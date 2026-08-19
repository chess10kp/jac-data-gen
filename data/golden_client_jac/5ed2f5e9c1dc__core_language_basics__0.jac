"""Package the DPO pairs into mlx-lm-lora train/valid splits.

Reads 01-sft-dpo/dataset/conversion/dpo.jsonl ({prompt, chosen, rejected, meta}), strips the
`meta` provenance, and writes 01-sft-dpo/dataset/mlx_dpo/{train,valid}.jsonl with exactly the
{prompt, chosen, rejected} keys that mlx_lm_lora's DPODataset expects (it wraps
prompt as the user turn and chosen/rejected as assistant turns via the chat
template). Stride split (every Nth -> valid) so valid stratifies across the set.

DPO is run by the third-party mlx-lm-lora trainer (mlx-lm 0.31.x has no native DPO);
see run_dpo.sh. Run from the repo root:
    jac run srccurrent/jacgen/build_dpo_splits.jac
"""

import json;
import from pathlib { Path }
import from typing { Any }

glob SRC: str = "01-sft-dpo/dataset/conversion/dpo.jsonl";
glob OUT_DIR: str = "01-sft-dpo/dataset/mlx_dpo";
glob VALID_EVERY: int = 10;  # every 10th pair -> valid (~10%)


with entry {
    p = Path(SRC);
    if not p.exists() {
        print("missing " + SRC + " -- run dpo_conversion.jac first");
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
            stripped: dict = {"prompt": str(rec["prompt"]),
                              "chosen": str(rec["chosen"]),
                              "rejected": str(rec["rejected"])};
            out: str = json.dumps(stripped);
            if i % VALID_EVERY == 0 { valid.append(out); } else { train.append(out); }
        }

        with open(OUT_DIR + "/train.jsonl", "w") as f {
            for l in train { f.write(l + "\n"); }
        }
        with open(OUT_DIR + "/valid.jsonl", "w") as f {
            for l in valid { f.write(l + "\n"); }
        }
        print("DPO train: " + str(len(train)) + "  valid: " + str(len(valid))
            + "  ({prompt,chosen,rejected}) -> " + OUT_DIR + "/");
    }
}
