"""Package the balanced training manifest into mlx-lm train/valid splits.

Reads 01-sft-dpo/dataset/conversion/sft_train.jsonl (the 1:3 balanced manifest), strips
each record to plain {"messages":[...]} (mlx-lm chat format; drops the `meta`
provenance), and writes 01-sft-dpo/dataset/mlx/{train,valid}.jsonl. The split is a stride
sample (every Nth -> valid) so it stratifies across the idiomatic + transpile
ordering rather than putting all transpile in valid.

Run from the repo root:
    jac run srccurrent/jacgen/build_splits.jac
"""

import json;
import from pathlib { Path }
import from typing { Any }

glob SRC: str = "01-sft-dpo/dataset/conversion/sft_train.jsonl";
glob OUT_DIR: str = "01-sft-dpo/dataset/mlx";
glob VALID_EVERY: int = 10;  # every 10th record -> valid (~10%)


with entry {
    p = Path(SRC);
    if not p.exists() {
        print("missing " + SRC + " -- run build_manifest.jac first");
    } else {
        lines: list[str] = [];
        for line in p.read_text().split("\n") {
            if line.strip() != "" { lines.append(line); }
        }

        Path(OUT_DIR).mkdir(parents=True, exist_ok=True);
        train: list[str] = [];
        valid: list[str] = [];
        for (i, line) in enumerate(lines) {
            rec: dict = dict(json.loads(line));
            stripped: dict = {"messages": rec["messages"]};
            out: str = json.dumps(stripped);
            if i % VALID_EVERY == 0 { valid.append(out); } else { train.append(out); }
        }

        with open(OUT_DIR + "/train.jsonl", "w") as f {
            for l in train { f.write(l + "\n"); }
        }
        with open(OUT_DIR + "/valid.jsonl", "w") as f {
            for l in valid { f.write(l + "\n"); }
        }
        print("train: " + str(len(train)) + "  valid: " + str(len(valid))
            + "  (messages-only) -> " + OUT_DIR + "/");
    }
}
