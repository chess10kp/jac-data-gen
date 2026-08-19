"""Build a supervised warm-start SFT set from the GOLD reference bodies.

The GRPO warm-start needs the base to produce correct completions sometimes
(pass > 0), else there is no success signal. At 0% base pass, rejection sampling
(rft_sample.jac) keeps nothing — but we already have every task's correct body in
`02-rl-grpo/dataset/rl/refbodies/<id>.txt`. So warm-start is *supervised*: teach the base
the gold completion for each TRAIN task, then GRPO refines.

Emits `02-rl-grpo/dataset/rl/rft/{train,valid}.jsonl` (mlx messages format) so `run_rft.sh`
reuses its existing SFT+fuse path (it skips sampling when that data exists).
Only TRAIN tasks are used — holdout stays unseen.

  jac run 02-rl-grpo/rl/build_sft_gold.jac
"""

import os;
import json;
import from pathlib { Path }

with entry {
    src = os.environ.get("JAC_RL_TRAIN", "02-rl-grpo/dataset/rl/train.jsonl");   # override for the conversion POC
    if not Path(src).exists() {
        print("MISSING " + src + " — run build_tasks + build_rl_splits first");
        import sys;
        sys.exit(1);
    }
    lines = [l for l in Path(src).read_text().split("\n") if l.strip()];
    rows: list = [];
    skipped = 0;
    for ln in lines {
        rec = json.loads(ln);
        meta = json.loads(rec["answer"]);
        tid = str(meta["id"]);
        rp = "02-rl-grpo/dataset/rl/refbodies/" + tid + ".txt";
        if not Path(rp).exists() {
            skipped += 1;
            continue;
        }
        gold = Path(rp).read_text();
        rows.append({
            "messages": [
                {"role": "user", "content": str(rec["prompt"])},
                {"role": "assistant", "content": "
