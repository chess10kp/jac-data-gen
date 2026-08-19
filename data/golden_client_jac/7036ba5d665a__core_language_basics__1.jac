"""Independently re-validate stored conversion examples through `jac run`.

Generation validates each example at creation; this is a separate integrity
audit that re-extracts the Jac from every stored line, runs it, and confirms
stdout still matches the recorded expected_output. Supports sampling (every
Nth line) so a full dataset can be spot-audited quickly.

Run from the repo root:
    jac run srccurrent/jacgen/verify_dataset.jac
"""

import json;
import os;
import from writer { revalidate_example }
import from pathlib { Path }
import from typing { Any }

glob FILES: list[str] = ["01-sft-dpo/dataset/conversion/sft.jsonl", "01-sft-dpo/dataset/conversion/sft_auto.jsonl"];
glob SAMPLE_EVERY: int = 1;  # 1 = check all; override with env JAC_SAMPLE_EVERY (e.g. 40)


def audit_file(path: str) -> dict {
    p = Path(path);
    if not p.exists() { return {"checked": 0, "failed": 0}; }
    every: int = int(os.environ.get("JAC_SAMPLE_EVERY", str(SAMPLE_EVERY)));
    if every < 1 { every = 1; }
    checked: int = 0;
    failed: int = 0;
    idx: int = 0;
    for line in p.read_text().split("\n") {
        if line.strip() == "" { continue; }
        idx += 1;
        if idx % every != 0 { continue; }
        rec: dict = dict(json.loads(line));
        (ok, detail) = revalidate_example(rec);
        checked += 1;
        if not ok {
            failed += 1;
            print("  FAIL " + path + " line " + str(idx) + ": " + detail);
        }
    }
    return {"checked": checked, "failed": failed};
}


with entry {
    total: int = 0;
    total_fail: int = 0;
    for f in FILES {
        r: dict = audit_file(f);
        checked: int = int(r["checked"]);
        failed: int = int(r["failed"]);
        total += checked;
        total_fail += failed;
        print(f + ": " + str(checked - failed) + "/" + str(checked) + " re-validated");
    }
    print("TOTAL: " + str(total - total_fail) + "/" + str(total) + " re-validated, "
        + str(total_fail) + " failed");
}
