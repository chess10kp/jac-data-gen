"""Pick the rung's train set: the first N tasks of the fixed train pool.

The ladder grows train-N over 1, 3, 5, 10, 20, all. Slicing the FRONT of a stable
`trainpool.jsonl` makes each rung a strict superset of the previous one (rung 5's
tasks include rung 3's), so the curve isolates "more tasks" as the only change.
Holdout is untouched — it was reserved once by build_rl_splits.jac.

  RUNG=5  jac run 02-rl-grpo/rl/pick_rung.jac      # train.jsonl = first 5 of trainpool
  RUNG=all jac run 02-rl-grpo/rl/pick_rung.jac     # train.jsonl = whole pool

Rebuilds the gold SFT set for these N tasks is the caller's job (build_sft_gold.jac).
"""

import os;
import from pathlib { Path }

with entry {
    pool_path = "02-rl-grpo/dataset/rl/trainpool.jsonl";
    if not Path(pool_path).exists() {
        print("MISSING " + pool_path + " — run: jac run 02-rl-grpo/rl/build_rl_splits.jac");
        import sys;
        sys.exit(1);
    }
    pool = [l for l in Path(pool_path).read_text().split("\n") if l.strip()];
    rung = os.environ.get("RUNG", "all");
    n = len(pool) if rung == "all" else min(int(rung), len(pool));

    train = pool[:n];
    Path("02-rl-grpo/dataset/rl/train.jsonl").write_text("\n".join(train) + ("\n" if train else ""));
    print("=== rung " + rung + " ===");
    print("  train.jsonl: " + str(len(train)) + " / " + str(len(pool)) + " pool tasks");
}
