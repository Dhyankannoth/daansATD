"""Trains the personal-baseline anomaly detector (Isolation Forest) and exports
it to flutterApp/assets/models/iforest.json.

Per Sagnik's spec: trained on REAL normal_rest/recovery/stress sessions only
(no synthetic substitute), using the 10-feature subset
[hr_z, hrv_z, rr_z, hr_slope_z, hrv_slope_z, rr_slope_z, hr_var_z, hrv_var_z,
rr_var_z, is_recovering], with the anomaly threshold set at the 99th
percentile of scores on a held-out "threshold" batch of normal data, separate
from both the training batch and the final test batch.

Usage (once real recordings exist):
    python train_isolation_forest.py --recordings-dir ../../recordings

Usage right now, before real data exists — proves the pipeline actually works
end-to-end so there are no surprises once real sessions land:
    python train_isolation_forest.py --self-test
"""

from __future__ import annotations

import argparse
import shutil
import tempfile

import numpy as np
from sklearn.ensemble import IsolationForest

from common import (
    ISOLATION_FOREST_FEATURES,
    FEATURE_SPEC_VERSION,
    export_tree,
    isolation_forest_score,
    load_recordings,
    split_by_session,
    write_model_json,
)


def train(
    recordings_dir: str,
    out_path: str,
    n_estimators: int = 100,
    max_samples: int = 256,
    seed: int = 0,
) -> None:
    df = load_recordings(recordings_dir, labels=["normal_rest", "recovery", "stress"])
    for label in ("normal_rest", "recovery", "stress"):
        n_sessions = df[df["label"] == label]["session_id"].nunique()
        if n_sessions == 0:
            raise ValueError(
                f"No '{label}' sessions found in {recordings_dir!r} — Isolation "
                "Forest needs real recordings for all three: normal_rest, recovery, stress."
            )
        print(f"  {label}: {n_sessions} session(s)")

    splits = split_by_session(df, {"train": 0.5, "threshold": 0.25, "test": 0.25}, seed=seed)
    print(
        f"Split {df['session_id'].nunique()} sessions -> "
        f"train={splits['train']['session_id'].nunique()}, "
        f"threshold={splits['threshold']['session_id'].nunique()}, "
        f"test={splits['test']['session_id'].nunique()} sessions"
    )

    X_train = splits["train"][ISOLATION_FOREST_FEATURES].to_numpy()
    max_samples_used = min(max_samples, len(X_train))
    clf = IsolationForest(
        n_estimators=n_estimators,
        max_samples=max_samples_used,
        random_state=seed,
    )
    clf.fit(X_train)

    trees_json = [export_tree(est.tree_) for est in clf.estimators_]

    # Threshold = 99th percentile of OUR OWN score formula (matching Dart exactly,
    # not sklearn's decision_function) on the held-out threshold batch.
    X_thresh = splits["threshold"][ISOLATION_FOREST_FEATURES].to_numpy()
    thresh_scores = [isolation_forest_score(trees_json, max_samples_used, row) for row in X_thresh]
    score_threshold = float(np.percentile(thresh_scores, 99))
    print(f"score_threshold (99th pct of held-out normal): {score_threshold:.4f}")

    # Report on the true held-out test batch, untouched by both training and
    # threshold-setting, so this number means something.
    X_test = splits["test"][ISOLATION_FOREST_FEATURES].to_numpy()
    test_scores = [isolation_forest_score(trees_json, max_samples_used, row) for row in X_test]
    flagged_frac = float(np.mean(np.array(test_scores) > score_threshold))
    print(
        f"On held-out test batch: {flagged_frac:.1%} of normal ticks would be flagged "
        f"anomalous at this threshold (expect ~1%, since the threshold is a 99th percentile)."
    )

    model_json = {
        "model_type": "isolation_forest",
        "feature_spec_version": FEATURE_SPEC_VERSION,
        "feature_indices": [0, 1, 2, 3, 4, 5, 6, 7, 8, 13],
        "max_samples": max_samples_used,
        "score_threshold": score_threshold,
        "classes": [],
        "trees": trees_json,
    }
    write_model_json(out_path, model_json)
    print(f"Wrote {out_path} ({len(trees_json)} trees)")


def self_test() -> None:
    """Generates synthetic recording CSVs matching the real format, runs the
    full train() pipeline against them, and checks the output loads back and
    scores sanely. Doesn't need real data — this is purely to catch bugs in
    this script itself before real sessions exist."""
    import os
    import pandas as pd
    from common import FEATURE_NAMES, RECORDING_META_COLUMNS

    tmp_dir = tempfile.mkdtemp(prefix="iforest_selftest_")
    try:
        rng = np.random.default_rng(42)

        def make_session(label: str, session_idx: int, n_rows: int = 90) -> pd.DataFrame:
            # Calm, low-variance feature rows for "normal-ish" synthetic data —
            # this is NOT a substitute for real sessions, just enough shape and
            # spread to exercise the training code path end-to-end.
            values = rng.normal(loc=0.0, scale=0.5, size=(n_rows, len(FEATURE_NAMES)))
            df = pd.DataFrame(values, columns=FEATURE_NAMES)
            df["is_recovering"] = 1.0 if label == "recovery" else 0.0
            df["is_resting"] = 1.0 if label == "normal_rest" else 0.0
            df["is_unknown"] = 0.0
            for col, val in [
                ("session_id", f"synthtest_{label}_{session_idx}"),
                ("person_id", "synthtest"),
                ("label", label),
                ("device_label", "self-test"),
                ("timestamp", 0),
                ("hr", 65.0), ("hrv", 60.0), ("rr", 14.0), ("spo2", None), ("ox_trend", None),
                ("quality", 0.9), ("rr_quality", 1.0), ("finger_present", True),
                ("activity", label), ("activity_confidence", 0.9), ("row_valid", True),
            ]:
                df[col] = val
            df["timestamp"] = range(n_rows)
            return df[RECORDING_META_COLUMNS + FEATURE_NAMES]

        for label in ("normal_rest", "recovery", "stress"):
            for i in range(3):  # 3 sessions per label, enough for a 3-way split
                make_session(label, i).to_csv(
                    os.path.join(tmp_dir, f"synthtest_{label}_{i}.csv"), index=False
                )

        out_path = os.path.join(tmp_dir, "iforest.json")
        train(tmp_dir, out_path, n_estimators=20, max_samples=32, seed=1)

        import json
        with open(out_path) as f:
            model = json.load(f)
        assert model["model_type"] == "isolation_forest"
        assert len(model["trees"]) == 20
        assert model["score_threshold"] is not None
        print("\nSELF-TEST PASSED — pipeline runs end-to-end and produces a loadable model.")
        print("(Scores/threshold are meaningless here — this used synthetic random data,")
        print(" not real physiological recordings. Re-run against real data when it lands.)")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recordings-dir", default="../../recordings")
    parser.add_argument("--out", default="../../flutterApp/assets/models/iforest.json")
    parser.add_argument("--n-estimators", type=int, default=100)
    parser.add_argument("--max-samples", type=int, default=256)
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument(
        "--self-test", action="store_true",
        help="Run against generated synthetic data instead of --recordings-dir, "
        "to verify the script itself works before real recordings exist.",
    )
    args = parser.parse_args()

    if args.self_test:
        self_test()
    else:
        train(args.recordings_dir, args.out, args.n_estimators, args.max_samples, args.seed)
