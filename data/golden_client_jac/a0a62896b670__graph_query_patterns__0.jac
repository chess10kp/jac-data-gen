"""Append-only DPO ingest for agent-authored rejected samples (Recipes R3b/R3c).

Complements dpo_conversion.jac (R3: rejected = mechanical py2jac transpile).
Here the rejected is AUTHORED: either deliberately Python-shaped Jac (R3b,
rejected_style=python_shaped_authored) or a runnable-but-non-OSP pure-function
solution to a graph task (R3c, rejected_style=non_osp_function).

Batch JSON at 01-sft-dpo/dataset/staging/dpo/<batch_id>.json:
    {"batch_id": "...", "generator": "fable-agent-v1",
     "pairs": [{"py","chosen_jac","rejected_jac","rejected_style",
                "recipe","difficulty","source"}]}

Gates per pair: chosen parses (chosen normally comes verbatim from an already
jac-run-gated sft.jsonl record, so parse is enough here); rejected passes the
same parse-only gate as dpo_conversion.jac; rouge_l(chosen, rejected) < 0.85
so the pair carries real contrast; python prompt decontaminated vs holdouts.
APPENDS to dpo.jsonl (never truncates). Receipt-guarded like ingest_batch.jac.

Run:  JAC_BATCH=01-sft-dpo/dataset/staging/dpo/d01.json \
    jac run 01-sft-dpo/sft_dpo/jacgen/dpo_authored.jac
"""

import json;
import os;
import subprocess;
import tempfile;
import from writer { append_jsonl }
import from dedup { rouge_l }
import from decontam { shingles, is_contaminated }
import from pathlib { Path }
import from typing { Any }

glob DPO_PATH: str = "01-sft-dpo/dataset/conversion/dpo.jsonl";
glob HOLDOUT_PATHS: list[str] = [
    "01-sft-dpo/dataset/eval_holdout/conversion.jsonl",
    "01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl"
];
glob RECEIPT_DIR: str = "01-sft-dpo/dataset/staging/receipts";
glob CONTRAST_MAX: float = 0.85;


def parses(jac_code: str) -> bool {
    # same parse-only gate as dpo_conversion.jac `compiles()`
    with tempfile.TemporaryDirectory() as d {
        fp = Path(str(d)) / "r.jac";
        fp.write_text(jac_code);
        try {
            proc = subprocess.run(["jac", "check", "-p", str(fp)], capture_output=True, text=True, timeout=30);
        } except (subprocess.SubprocessError, OSError) {
            return False;
        }
        return proc.returncode == 0;
    }
}


def holdout_shingles() -> dict {
    s: dict[str, int] = {};
    for path in HOLDOUT_PATHS {
        p = Path(path);
        if not p.exists() { continue; }
        for line in p.read_text().split("\n") {
            if line.strip() == "" { continue; }
            rec: dict = dict(json.loads(line));
            for sh in shingles(str(rec["python"])) { s[sh] = 1; }
        }
    }
    return s;
}


with entry {
    batch_path: str = os.environ.get("JAC_BATCH", "");
    if batch_path == "" or not Path(batch_path).exists() {
        print("set JAC_BATCH to a staging json path");
    } else {
        batch: dict = dict(json.loads(Path(batch_path).read_text()));
        batch_id: str = str(batch["batch_id"]);
        receipt_path = Path(RECEIPT_DIR) / (batch_id + ".json");
        if receipt_path.exists() {
            print("REFUSE: receipt exists for " + batch_id + " (already ingested)");
        } else {
            holdout: dict = holdout_shingles();
            accepted: int = 0;
            rejected: list = [];
            for pr_any in list(batch["pairs"]) {
                pr: dict = dict(pr_any);
                py: str = str(pr["py"]).strip();
                chosen: str = str(pr["chosen_jac"]).strip();
                rej: str = str(pr["rejected_jac"]).strip();
                style: str = str(pr["rejected_style"]);
                tag: str = py.split("\n", 1)[0][:60];

                if is_contaminated(py, holdout) {
                    rejected.append({"tag": tag, "reason": "contaminated vs holdout"});
                    continue;
                }
                if not parses(chosen) {
                    rejected.append({"tag": tag, "reason": "chosen parse fail"});
                    continue;
                }
                if not parses(rej) {
                    rejected.append({"tag": tag, "reason": "rejected parse fail"});
                    continue;
                }
                if rouge_l(chosen, rej) >= CONTRAST_MAX {
                    rejected.append({"tag": tag, "reason": "no contrast (rouge >= 0.85)"});
                    continue;
                }
                prompt: str = "Convert this Python to idiomatic Jac:\n\n
