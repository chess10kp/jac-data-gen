"""Confirm the eval holdout shares no near-duplicate task with the training set.

14-gram overlap of every holdout Python against all training Python. Any line
above the 0.5 Jaccard threshold is reported. Expect 0.

Run from the repo root:
    jac run srccurrent/jacgen/decontam_report.jac
"""

import json;
import from decontam { build_training_shingles, is_contaminated }
import from pathlib { Path }
import from typing { Any }

glob TRAIN: list[str] = ["01-sft-dpo/dataset/conversion/sft.jsonl", "01-sft-dpo/dataset/conversion/sft_auto.jsonl"];
glob HOLDOUT: str = "01-sft-dpo/dataset/eval_holdout/conversion.jsonl";


with entry {
    train: dict = build_training_shingles(TRAIN);
    print("training shingles: " + str(len(train)));

    p = Path(HOLDOUT);
    total: int = 0;
    contam: int = 0;
    for line in p.read_text().split("\n") {
        if line.strip() == "" { continue; }
        rec: dict = dict(json.loads(line));
        py: str = str(rec["python"]);
        total += 1;
        if is_contaminated(py, train) {
            contam += 1;
            print("  CONTAMINATED: " + str(rec["func_name"]));
        }
    }
    print("holdout decontam: " + str(total - contam) + "/" + str(total) + " clean, "
        + str(contam) + " contaminated");
}
