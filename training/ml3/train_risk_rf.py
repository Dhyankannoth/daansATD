"""Trains the secondary risk classifier (Random Forest, P(reaction)) and
exports it to flutterApp/assets/models/risk_rf.json.

Per Sagnik's spec:
  Positives: synthetic reaction trajectories, replayed through the app's real
             pipeline (ReplayVitalsSource) with Record Mode on, labeled "reaction".
  Negatives: all real recordings (normal_rest, recovery, stress, artifact
             sessions that passed the quality gate), plus optional synthetic
             normal variation.
  Features: all 16 (feature_spec.json's risk_classifier subset).
  Output:   P(reaction) — a secondary corroborating signal, never the sole
            decision-maker (the rule engine in fusion_engine.dart owns that).

Usage (once real + synthetic-replay recordings exist):
    python train_risk_rf.py --recordings-dir ../../recordings

Usage right now, before real data exists:
    python train_risk_rf.py --self-test
"""

from __future__ import annotations

import argparse
import shutil
import tempfile

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score

from common import (
    FEATURE_SPEC_VERSION,
    REACTION_LABEL,
    RISK_CLASSIFIER_FEATURES,
    export_tree,
    load_recordings,
    split_by_session,
    write_model_json,
)

NEGATIVE_LABELS = ["normal_rest", "recovery", "stress", "artifact"]


def train(
    recordings_dir: str,
    out_path: str,
    n_estimators: int = 200,
    seed: int = 0,
) -> None:
    df = load_recordings(recordings_dir, labels=NEGATIVE_LABELS + [REACTION_LABEL])

    n_reaction_sessions = df[df["label"] == REACTION_LABEL]["session_id"].nunique()
    if n_reaction_sessions == 0:
        raise ValueError(
            f"No '{REACTION_LABEL}'-labeled sessions found in {recordings_dir!r}. "
            "Replay a synthetic reaction trace through ReplayVitalsSource with "
            "Record Mode on, labeled 'reaction', to produce positives."
        )
    for label in NEGATIVE_LABELS:
        n = df[df["label"] == label]["session_id"].nunique()
        print(f"  {label}: {n} session(s)")
    print(f"  {REACTION_LABEL}: {n_reaction_sessions} session(s)")

    df = df.copy()
    df["y"] = (df["label"] == REACTION_LABEL).astype(int)

    splits = split_by_session(df, {"train": 0.7, "test": 0.3}, seed=seed)
    train_df, test_df = splits["train"], splits["test"]
    print(
        f"Split {df['session_id'].nunique()} sessions -> "
        f"train={train_df['session_id'].nunique()}, test={test_df['session_id'].nunique()} sessions "
        f"({len(train_df)} train rows, {len(test_df)} test rows)"
    )
    if train_df["y"].nunique() < 2:
        raise ValueError(
            "Training split ended up with only one class present — need at least one "
            "'reaction' session and one non-reaction session in the train split. "
            "Record more sessions of whichever class is missing."
        )

    X_train = train_df[RISK_CLASSIFIER_FEATURES].to_numpy()
    y_train = train_df["y"].to_numpy()
    clf = RandomForestClassifier(
        n_estimators=n_estimators,
        random_state=seed,
        class_weight="balanced",  # reaction sessions will be far rarer than normal ones
    )
    clf.fit(X_train, y_train)

    if test_df["y"].nunique() == 2:
        X_test = test_df[RISK_CLASSIFIER_FEATURES].to_numpy()
        y_test = test_df["y"].to_numpy()
        probs = clf.predict_proba(X_test)[:, list(clf.classes_).index(1)]
        auc = roc_auc_score(y_test, probs)
        print(f"Held-out test AUC: {auc:.3f}")
    else:
        print(
            "Held-out test split has only one class present — can't compute AUC "
            "yet. Not a failure, just means more sessions of the missing class "
            "are needed for a real evaluation."
        )

    # classes_ order must line up with each tree's per-node value columns —
    # sklearn guarantees this internally, so exporting classes_ alongside the
    # trees as-is (not re-sorted) is correct. Map 0/1 back to real label
    # strings so Dart's classes.indexOf('reaction') works.
    class_names = ["reaction" if c == 1 else "normal" for c in clf.classes_]

    trees_json = [export_tree(est.tree_) for est in clf.estimators_]
    model_json = {
        "model_type": "random_forest",
        "feature_spec_version": FEATURE_SPEC_VERSION,
        "feature_indices": list(range(16)),
        "max_samples": None,
        "score_threshold": None,
        "classes": class_names,
        "trees": trees_json,
    }
    write_model_json(out_path, model_json)
    print(f"Wrote {out_path} ({len(trees_json)} trees)")


def self_test() -> None:
    """Generates synthetic recording CSVs (both non-reaction and reaction-
    labeled), runs the full train() pipeline, and checks the output loads
    back correctly. Proves the script itself works before real + replayed
    data exists."""
    import os
    import pandas as pd
    from common import FEATURE_NAMES, RECORDING_META_COLUMNS

    tmp_dir = tempfile.mkdtemp(prefix="risk_rf_selftest_")
    try:
        rng = np.random.default_rng(7)

        def make_session(label: str, session_idx: int, n_rows: int = 90) -> pd.DataFrame:
            is_reaction = label == REACTION_LABEL
            # Reaction-labeled synthetic rows get shifted/scaled z-scores so the
            # classifier has *something* separable to learn in this smoke test —
            # this is not a substitute for real reaction trajectories.
            loc = 2.0 if is_reaction else 0.0
            values = rng.normal(loc=loc, scale=0.5, size=(n_rows, len(FEATURE_NAMES)))
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

        for label in NEGATIVE_LABELS:
            for i in range(3):
                make_session(label, i).to_csv(
                    os.path.join(tmp_dir, f"synthtest_{label}_{i}.csv"), index=False
                )
        for i in range(4):
            make_session(REACTION_LABEL, i).to_csv(
                os.path.join(tmp_dir, f"synthtest_{REACTION_LABEL}_{i}.csv"), index=False
            )

        out_path = os.path.join(tmp_dir, "risk_rf.json")
        train(tmp_dir, out_path, n_estimators=30, seed=1)

        import json
        with open(out_path) as f:
            model = json.load(f)
        assert model["model_type"] == "random_forest"
        assert REACTION_LABEL in model["classes"]
        assert len(model["trees"]) == 30
        print("\nSELF-TEST PASSED — pipeline runs end-to-end and produces a loadable model.")
        print("(AUC above is meaningless here — synthetic random data, not real")
        print(" reaction trajectories. Re-run against real + replayed data when it lands.)")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recordings-dir", default="../../recordings")
    parser.add_argument("--out", default="../../flutterApp/assets/models/risk_rf.json")
    parser.add_argument("--n-estimators", type=int, default=200)
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
        train(args.recordings_dir, args.out, args.n_estimators, args.seed)
