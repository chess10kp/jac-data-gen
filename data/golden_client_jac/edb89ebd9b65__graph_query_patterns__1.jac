"""Append-only growth of the graph eval holdout (13 -> ~33 tasks).

Batch JSON at 01-sft-dpo/dataset/staging/holdout/<batch_id>.json, entries in
graph_data/holdout.json shape:
    {"batch_id": "...",
     "tasks": [{"name","py","jac_reference","cases":[{"input","output"},...]}]}

Gates per task: python3 produces the recorded output on EVERY case; the
reference Jac runs every case too (proves the task is solvable in idiomatic
Jac -- the reference is NOT stored in the holdout); name disjoint from
existing holdout + train; python decontaminated vs the TRAIN set (native
decontam direction: build_training_shingles over sft.jsonl + sft_auto.jsonl).

APPENDS to eval_holdout/graph_conversion.jsonl in its existing record shape:
    {"func_name","python","prompt","test_cases","source"}
NEVER run graph_holdout.jac after this (it truncates). Receipt-guarded.

Run:  JAC_BATCH=01-sft-dpo/dataset/staging/holdout/h01.json \
    jac run 01-sft-dpo/sft_dpo/jacgen/ingest_holdout.jac
"""

import json;
import os;
import subprocess;
import tempfile;
import from writer { run_jac }
import from decontam { build_training_shingles, is_contaminated }
import from pathlib { Path }
import from typing { Any }

glob HOLDOUT_PATH: str = "01-sft-dpo/dataset/eval_holdout/graph_conversion.jsonl";
glob TRAIN_PATHS: list = [
    "01-sft-dpo/dataset/conversion/sft.jsonl",
    "01-sft-dpo/dataset/conversion/sft_auto.jsonl"
];
glob RECEIPT_DIR: str = "01-sft-dpo/dataset/staging/receipts";


def run_python(py: str, name: str, inp: Any, timeout: int = 10) -> tuple[int, str] {
    src: str = py + "\n\nprint(" + name + "(" + repr(inp) + "))\n";
    with tempfile.TemporaryDirectory() as d {
        f = Path(str(d)) / "check.py";
        f.write_text(src);
        try {
            p = subprocess.run(["python3", str(f)], capture_output=True, text=True, timeout=timeout);
            return (p.returncode, p.stdout.strip());
        } except (subprocess.SubprocessError, OSError) as e {
            return (124, str(e));
        }
    }
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
            train: dict = build_training_shingles(TRAIN_PATHS);
            taken: dict[str, int] = {};
            hp = Path(HOLDOUT_PATH);
            if hp.exists() {
                for line in hp.read_text().split("\n") {
                    if line.strip() == "" { continue; }
                    taken[str(dict(json.loads(line))["func_name"])] = 1;
                }
            }

            accepted: list = [];
            rejected: list = [];
            for t_any in list(batch["tasks"]) {
                t: dict = dict(t_any);
                name: str = str(t["name"]);
                py: str = str(t["py"]).strip();
                ref: str = str(t["jac_reference"]).strip().split("with entry", 1)[0].strip();
                cases: list = list(t["cases"]);
                if name in taken {
                    rejected.append({"name": name, "reason": "name already in holdout"});
                    continue;
                }
                if is_contaminated(py, train) {
                    rejected.append({"name": name, "reason": "contaminated vs train"});
                    continue;
                }
                ok: bool = len(cases) > 0;
                why: str = "no cases";
                for c in cases {
                    cd: dict = dict(c);
                    want: str = str(cd["output"]).strip();
                    (prc, pout) = run_python(py, name, cd["input"]);
                    if prc != 0 or pout != want {
                        ok = False; why = "python mismatch on " + repr(cd["input"])[:60];
                        break;
                    }
                    demo: str = ref + "\n\nwith entry {\n    print(" + name + "(" + repr(cd["input"]) + "));\n}";
                    (jrc, jout, jerr) = run_jac(demo);
                    if jrc != 0 or jout.strip() != want {
                        ok = False; why = "reference jac mismatch on " + repr(cd["input"])[:60];
                        break;
                    }
                }
                if not ok {
                    rejected.append({"name": name, "reason": why});
                    continue;
                }
                prompt: str = "Convert this Python to idiomatic Jac:\n\n
