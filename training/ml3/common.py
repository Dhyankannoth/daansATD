"""Shared utilities for ML-3 model training.

Everything here matches flutterApp's Dart engine exactly, on purpose:
- FEATURE_NAMES / feature index subsets come from assets/config/feature_spec.json.
- The recordings CSV format matches flutterApp/lib/engine/record/record_mode_writer.dart's
  _header() exactly (column names, order).
- export_tree() produces the same TreeNode JSON shape that
  flutterApp/lib/engine/ml/tree_model.dart's TreeNode.fromJson expects, which is
  sklearn's own tree_ representation (feature/threshold/children_left/children_right/
  n_node_samples/value) with almost no transformation needed.

If feature_spec.json's `version` or feature list ever changes, update FEATURE_SPEC_VERSION
and FEATURE_NAMES here to match, or these scripts will silently train against the wrong
feature layout.
"""

from __future__ import annotations

import glob
import json
import math
import os
from dataclasses import dataclass

import numpy as np
import pandas as pd

FEATURE_SPEC_VERSION = 1

# Index order matches assets/config/feature_spec.json exactly.
FEATURE_NAMES = [
    "hr_z", "hrv_z", "rr_z",
    "hr_slope_z", "hrv_slope_z", "rr_slope_z",
    "hr_var_z", "hrv_var_z", "rr_var_z",
    "hr_pct", "hrv_pct", "rr_pct",
    "is_resting", "is_recovering", "is_unknown",
    "since_exercise",
]

# feature_spec.json's model_subsets, by name (indices there are into FEATURE_NAMES).
ISOLATION_FOREST_FEATURES = [FEATURE_NAMES[i] for i in [0, 1, 2, 3, 4, 5, 6, 7, 8, 13]]
RISK_CLASSIFIER_FEATURES = list(FEATURE_NAMES)  # all 16, in order

# record_mode_writer.dart's _header(), the fixed (non-feature) columns.
RECORDING_META_COLUMNS = [
    "session_id", "person_id", "label", "device_label", "timestamp",
    "hr", "hrv", "rr", "spo2", "ox_trend", "quality", "rr_quality",
    "finger_present", "activity", "activity_confidence", "row_valid",
]

REACTION_LABEL = "reaction"
EULER_GAMMA = 0.5772156649


def load_recordings(recordings_dir: str, labels: list[str] | None = None) -> pd.DataFrame:
    """Loads every *.csv in recordings_dir (skipping *_raw.csv sidecar files),
    filters to row_valid == True (the only rows with real feature values), and
    optionally restricts to a set of labels.

    Returns a DataFrame with RECORDING_META_COLUMNS + FEATURE_NAMES columns.
    session_id is preserved so callers can split by session, never by row.
    """
    paths = sorted(
        p for p in glob.glob(os.path.join(recordings_dir, "*.csv"))
        if not p.endswith("_raw.csv")
    )
    if not paths:
        raise FileNotFoundError(
            f"No recording CSVs found in {recordings_dir!r}. Expected files written "
            "by the app's Record Mode (see flutterApp/lib/engine/record/record_mode_writer.dart)."
        )

    frames = []
    for p in paths:
        df = pd.read_csv(p)
        missing = set(RECORDING_META_COLUMNS + FEATURE_NAMES) - set(df.columns)
        if missing:
            raise ValueError(
                f"{p} is missing expected columns {sorted(missing)} — either it predates "
                "the current feature_spec.json, or featureNames wasn't wired correctly "
                "when this file was recorded."
            )
        frames.append(df)

    full = pd.concat(frames, ignore_index=True)
    full = full[full["row_valid"] == True]  # noqa: E712 (pandas bool column)
    if labels is not None:
        full = full[full["label"].isin(labels)]
    return full.reset_index(drop=True)


def split_by_session(
    df: pd.DataFrame,
    fractions: dict[str, float],
    seed: int = 0,
) -> dict[str, pd.DataFrame]:
    """Splits by unique session_id (never by row), so the same recording never
    ends up in two splits — this is the thing Sagnik's spec is explicit about:
    "Don't reuse the same recording three times."

    `fractions` e.g. {"train": 0.5, "threshold": 0.25, "test": 0.25}, must sum to ~1.0.
    With very few sessions (a real risk early on), each split gets at least one
    session if there are enough sessions to go around at all.
    """
    sessions = df["session_id"].unique().tolist()
    rng = np.random.default_rng(seed)
    rng.shuffle(sessions)

    n = len(sessions)
    if n < len(fractions):
        raise ValueError(
            f"Only {n} distinct session(s) available but {len(fractions)} splits "
            f"requested ({list(fractions)}) — record more sessions first. "
            "Reusing one session across splits defeats the point of the split."
        )

    names = list(fractions.keys())
    counts = [max(1, round(f * n)) for f in fractions.values()]
    # Fix up rounding so counts sum exactly to n (give leftover/shortfall to the
    # largest split, typically "train").
    diff = n - sum(counts)
    counts[counts.index(max(counts))] += diff

    result = {}
    idx = 0
    for name, count in zip(names, counts):
        chosen = set(sessions[idx: idx + count])
        result[name] = df[df["session_id"].isin(chosen)].reset_index(drop=True)
        idx += count
    return result


def export_tree(tree_) -> dict:
    """Converts an sklearn fitted tree_ (from a DecisionTreeClassifier,
    IsolationForest's underlying ExtraTreeRegressor, or a
    GradientBoostingRegressor's underlying DecisionTreeRegressor) into the
    JSON shape tree_model.dart's TreeNode.fromJson expects.

    sklearn already uses feature=-2, threshold=-2.0 at leaves and
    children_left=children_right=-1 — exactly what Dart's isLeaf() checks —
    so this is a direct field rename, not a real transformation.
    """
    value = tree_.value  # shape (n_nodes, n_outputs, n_classes_or_1)
    # Single-output trees (our case, always): squeeze the middle dimension.
    value_2d = [row[0].tolist() for row in value]
    return {
        "feature": tree_.feature.tolist(),
        "threshold": tree_.threshold.tolist(),
        "left": tree_.children_left.tolist(),
        "right": tree_.children_right.tolist(),
        "n_samples": tree_.n_node_samples.tolist(),
        "value": value_2d,
    }


def write_model_json(path: str, model_json: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(model_json, f, indent=2)


# ---- Python-side replica of isolation_forest.dart, for threshold-setting and
# validating an exported model reproduces the expected scores before shipping it.

def _c(n: float) -> float:
    if n <= 1:
        return 0.0
    return 2 * (math.log(n - 1) + EULER_GAMMA) - 2 * (n - 1) / n


def _path_length(tree_json: dict, x: list[float]) -> float:
    node = 0
    depth = 0
    left, right = tree_json["left"], tree_json["right"]
    feature, threshold = tree_json["feature"], tree_json["threshold"]
    while not (left[node] == -1 and right[node] == -1):
        f, t = feature[node], threshold[node]
        node = left[node] if x[f] <= t else right[node]
        depth += 1
    return depth + _c(tree_json["n_samples"][node])


def isolation_forest_score(trees_json: list[dict], max_samples: int, x: list[float]) -> float:
    """Exact port of IsolationForest.score() in isolation_forest.dart — use this,
    not sklearn's own score_samples/decision_function, to pick score_threshold
    and to sanity-check an exported model, since Dart recomputes from the raw
    trees at runtime rather than trusting a precomputed sklearn score."""
    paths = [_path_length(t, x) for t in trees_json]
    mean_path = sum(paths) / len(paths)
    c_max = _c(max_samples)
    if c_max == 0:
        return 0.0
    return 2 ** (-mean_path / c_max)
