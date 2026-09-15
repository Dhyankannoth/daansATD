import '../core/config/thresholds.dart';
import '../core/models/frame_sample.dart';
import '../core/models/vitals_reading.dart';
import '../dsp/bandpass.dart' show bandpass;
import '../dsp/peaks.dart' show findBeats;
import '../dsp/resample.dart' show resampleLinear, binAverage;
import '../dsp/spectrum.dart' show dominantRate, DominantRateResult;
import '../dsp/stats.dart' show mean, std;
import 'heart.dart' show computeHr, computeRmssd;
import 'oxygenation.dart' show OxCalibration, OxygenationTracker;
import 'quality.dart' show computeQuality;
import 'respiration.dart' show computeRr;

class _Gap {
  const _Gap(this.start, this.end);
  final double start;
  final double end;
}

class _Grids {
  const _Grids(this.times, this.red, this.green, this.fs, this.tStart, this.tEnd);
  final List<double> times;
  final List<double> red;
  final List<double> green;
  final double fs;
  final double tStart;
  final double tEnd;
}

/// Derives one [VitalsReading] per second from the recent window of camera
/// [FrameSample]s. Stateful only in the oxygenation reference, which is
/// reset per scan via [resetScan].
class VitalsEngine {
  VitalsEngine({required this.thresholds})
      : _ox = OxygenationTracker(referenceWindows: thresholds.spo2.referenceWindows);

  final Thresholds thresholds;
  final OxygenationTracker _ox;

  void resetScan() => _ox.reset();

  VitalsReading tick({
    required List<FrameSample> buffer,
    required double nowS,
    required int nowMs,
    OxCalibration? oxCalibration,
    VitalsReadingSource source = VitalsReadingSource.camera,
  }) {
    final analysisStart = nowS - thresholds.windowsS.analysis;
    final window = buffer.where((s) => s.t >= analysisStart && s.t <= nowS).toList();

    final fingerPresent = _majorityFingerPresent(buffer, nowS);

    if (window.length < 2) {
      return VitalsReading(
        timestamp: nowMs,
        hr: null,
        hrv: null,
        rr: null,
        spo2: null,
        oxTrend: null,
        quality: 0,
        rrQuality: 0,
        fingerPresent: fingerPresent,
        source: source,
      );
    }

    final grids = _buildGrids(window, thresholds.filter.resampleHz);
    if (grids == null) {
      return VitalsReading(
        timestamp: nowMs,
        hr: null,
        hrv: null,
        rr: null,
        spo2: null,
        oxTrend: null,
        quality: 0,
        rrQuality: 0,
        fingerPresent: fingerPresent,
        source: source,
      );
    }

    final f = thresholds.filter;
    final filteredRed = bandpass(grids.red, grids.fs,
        lowHz: f.bandpassLowHz, highHz: f.bandpassHighHz, padS: f.padS);
    final filteredGreen = bandpass(grids.green, grids.fs,
        lowHz: f.bandpassLowHz, highHz: f.bandpassHighHz, padS: f.padS);

    final gaps = _findGaps(window, thresholds.quality.maxGapS);

    final b = thresholds.beats;
    final beatsRedRel = findBeats(filteredRed, grids.fs,
        minGapS: b.minGapS, minHeightSd: b.minHeightSd, edgeIgnoreS: b.edgeIgnoreS);
    final beatsRedAbs = beatsRedRel
        .map((t) => grids.tStart + t)
        .where((t) => !_inGap(t, gaps))
        .toList();

    final hrWindowStart = nowS - thresholds.windowsS.hr;
    final hrvWindowStart = nowS - thresholds.windowsS.hrv;

    var hrBeats = beatsRedAbs.where((t) => t >= hrWindowStart && t <= nowS).toList();
    var hrResult = computeHr(hrBeats,
        ibiMinS: b.ibiMinS,
        ibiMaxS: b.ibiMaxS,
        hrIbiTolerance: b.hrIbiTolerance,
        hrMinIntervals: b.hrMinIntervals);

    var beatsAbs = beatsRedAbs;
    var usedGreen = false;

    if (hrResult == null) {
      final beatsGreenRel = findBeats(filteredGreen, grids.fs,
          minGapS: b.minGapS, minHeightSd: b.minHeightSd, edgeIgnoreS: b.edgeIgnoreS);
      final beatsGreenAbs = beatsGreenRel
          .map((t) => grids.tStart + t)
          .where((t) => !_inGap(t, gaps))
          .toList();
      final greenHrBeats =
          beatsGreenAbs.where((t) => t >= hrWindowStart && t <= nowS).toList();
      final greenHrResult = computeHr(greenHrBeats,
          ibiMinS: b.ibiMinS,
          ibiMaxS: b.ibiMaxS,
          hrIbiTolerance: b.hrIbiTolerance,
          hrMinIntervals: b.hrMinIntervals);
      if (greenHrResult != null) {
        hrResult = greenHrResult;
        hrBeats = greenHrBeats;
        beatsAbs = beatsGreenAbs;
        usedGreen = true;
      }
    }

    final hrvBeats = beatsAbs.where((t) => t >= hrvWindowStart && t <= nowS).toList();
    final hrv = computeRmssd(hrvBeats,
        hrvIbiTolerance: b.hrvIbiTolerance,
        hrvMinIntervals: b.hrvMinIntervals,
        hrvMinPairs: b.hrvMinPairs);

    final q = thresholds.quality;
    final hrWindowOk = _windowOk(window, thresholds.windowsS.hr, nowS,
        minValidFrac: q.minValidFrac, maxGapS: q.maxGapS);

    final hrSubStart = nowS - thresholds.windowsS.hr;
    final subIdxStart =
        ((hrSubStart - grids.tStart) * grids.fs).round().clamp(0, filteredRed.length);
    final redSub = filteredRed.sublist(subIdxStart);
    final greenSub = filteredGreen.sublist(subIdxStart);

    final validFrac = _validFrac(window, thresholds.windowsS.hr, nowS);
    final quality = computeQuality(
      hrWindowOk: hrWindowOk && hrResult != null,
      validFrac: validFrac,
      keptFrac: hrResult?.keptFrac ?? 0,
      filteredRed: redSub,
      filteredGreen: greenSub,
    );

    // --- Respiration ---
    final rrMaxS = thresholds.windowsS.rrMax;
    final rrMinS = thresholds.windowsS.rrMin;
    final availableS = (grids.tEnd - grids.tStart).clamp(0, rrMaxS);
    double? rr;
    double rrQuality = 0;
    if (availableS >= rrMinS) {
      final rrWindowStartT = nowS - availableS;
      final startIdx =
          ((rrWindowStartT - grids.tStart) * grids.fs).round().clamp(0, grids.red.length);
      final redRaw = grids.red.sublist(startIdx);
      final intensityBinned =
          binAverage(redRaw, grids.fs, 1.0 / f.respHz);

      final rrBeats = (usedGreen ? beatsAbs : beatsRedAbs)
          .where((t) => t >= rrWindowStartT && t <= nowS)
          .toList();
      final intervalTimes = <double>[];
      final intervalValues = <double>[];
      for (var i = 1; i < rrBeats.length; i++) {
        final interval = rrBeats[i] - rrBeats[i - 1];
        if (interval >= b.ibiMinS && interval <= b.ibiMaxS) {
          intervalTimes.add(rrBeats[i]);
          intervalValues.add(interval);
        }
      }

      final intensityResult = dominantRate(
          intensityBinned, f.respHz, f.respBandHz, f.respStepHz,
          minSamples: (rrMinS * f.respHz).round());

      DominantRateResult? intervalResult;
      if (intervalTimes.length >= 2) {
        final intervalGrid = resampleLinear(
            intervalTimes, intervalValues, f.respHz, rrWindowStartT, nowS);
        intervalResult = dominantRate(
            intervalGrid, f.respHz, f.respBandHz, f.respStepHz,
            minSamples: (rrMinS * f.respHz).round());
      }

      final rrResult = computeRr(
        intensityResult: intensityResult,
        intervalResult: intervalResult,
        minProminence: thresholds.resp.minProminence,
        agreeBpm: thresholds.resp.agreeBpm,
        agreeQuality: thresholds.resp.agreeQuality,
        singleQuality: thresholds.resp.singleQuality,
      );
      rr = rrResult.rr;
      rrQuality = rrResult.rrQuality;
    }

    // --- Oxygenation ---
    final spo2WindowS = thresholds.windowsS.spo2;
    final spo2Start = nowS - spo2WindowS;
    final spo2Idx =
        ((spo2Start - grids.tStart) * grids.fs).round().clamp(0, filteredRed.length);
    final redFilteredSub = filteredRed.sublist(spo2Idx);
    final greenFilteredSub = filteredGreen.sublist(spo2Idx);
    final redRawSub = grids.red.sublist(spo2Idx.clamp(0, grids.red.length));
    final greenRawSub = grids.green.sublist(spo2Idx.clamp(0, grids.green.length));

    final acRed = std(redFilteredSub);
    final dcRed = mean(redRawSub);
    final acGreen = std(greenFilteredSub);
    final dcGreen = mean(greenRawSub);

    final qualityTrusted = quality >= q.trusted;
    final oxResult = _ox.tick(
      acRed: acRed,
      dcRed: dcRed,
      acGreen: acGreen,
      dcGreen: dcGreen,
      qualityTrusted: qualityTrusted,
      calibration: oxCalibration,
    );

    var finalHr = hrResult?.hr;
    var finalHrv = hrv;
    var finalRr = rr;
    var finalOxTrend = oxResult.oxTrend;
    if (quality < q.displayMin) {
      finalHr = null;
      finalHrv = null;
      finalRr = null;
      finalOxTrend = null;
    }

    return VitalsReading(
      timestamp: nowMs,
      hr: finalHr,
      hrv: finalHrv,
      rr: finalRr,
      spo2: oxResult.spo2,
      oxTrend: finalOxTrend,
      quality: quality,
      rrQuality: rrQuality,
      fingerPresent: fingerPresent,
      source: source,
    );
  }

  _Grids? _buildGrids(List<FrameSample> window, double resampleHz) {
    final validSamples = window.where((s) => s.valid).toList();
    if (validSamples.length < 2) return null;
    final times = validSamples.map((s) => s.t).toList();
    final redValues = validSamples.map((s) => s.r).toList();
    final greenValues = validSamples.map((s) => s.g).toList();
    final tStart = window.first.t;
    final tEnd = window.last.t;
    final red = resampleLinear(times, redValues, resampleHz, tStart, tEnd);
    final green = resampleLinear(times, greenValues, resampleHz, tStart, tEnd);
    return _Grids(times, red, green, resampleHz, tStart, tEnd);
  }

  bool _majorityFingerPresent(List<FrameSample> buffer, double nowS) {
    final lastSecond = buffer.where((s) => s.t >= nowS - 1 && s.t <= nowS).toList();
    if (lastSecond.isEmpty) return false;
    final present = lastSecond.where((s) => s.fingerPresent).length;
    return present * 2 >= lastSecond.length;
  }

  double _validFrac(List<FrameSample> window, double subWindowS, double nowS) {
    final sub = window.where((s) => s.t >= nowS - subWindowS && s.t <= nowS).toList();
    if (sub.isEmpty) return 0;
    return sub.where((s) => s.valid).length / sub.length;
  }

  bool _windowOk(
    List<FrameSample> window,
    double subWindowS,
    double nowS, {
    required double minValidFrac,
    required double maxGapS,
  }) {
    final sub = window.where((s) => s.t >= nowS - subWindowS && s.t <= nowS).toList();
    if (sub.isEmpty) return false;
    final validFrac = sub.where((s) => s.valid).length / sub.length;
    if (validFrac < minValidFrac) return false;
    final validTimes = sub.where((s) => s.valid).map((s) => s.t).toList();
    if (validTimes.length < 2) return false;
    for (var i = 1; i < validTimes.length; i++) {
      if (validTimes[i] - validTimes[i - 1] > maxGapS) return false;
    }
    return true;
  }

  List<_Gap> _findGaps(List<FrameSample> samples, double maxGapS) {
    final gaps = <_Gap>[];
    var i = 0;
    while (i < samples.length) {
      if (!samples[i].valid) {
        final startT = samples[i].t;
        var j = i;
        while (j < samples.length && !samples[j].valid) {
          j++;
        }
        final endT = j < samples.length ? samples[j].t : samples.last.t;
        if (endT - startT > maxGapS) gaps.add(_Gap(startT, endT));
        i = j;
      } else {
        i++;
      }
    }
    return gaps;
  }

  bool _inGap(double t, List<_Gap> gaps) {
    for (final g in gaps) {
      if (t >= g.start && t <= g.end) return true;
    }
    return false;
  }
}
