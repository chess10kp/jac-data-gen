"""Report conversion-dataset composition across all SFT/DPO files.

Run from the repo root:
    jac run srccurrent/jacgen/dataset_stats.jac
"""

import json;
import from pathlib { Path }
import from typing { Any }

glob SFT_FILES: list[str] = ["01-sft-dpo/dataset/conversion/sft.jsonl", "01-sft-dpo/dataset/conversion/sft_auto.jsonl"];
glob DPO_FILE: str = "01-sft-dpo/dataset/conversion/dpo.jsonl";


def count_file(path: str) -> dict {
    by_diff: dict[str, int] = {};
    by_gen: dict[str, int] = {};
    by_source: dict[str, int] = {};
    total: int = 0;
    p = Path(path);
    if not p.exists() { return {"total": 0, "by_diff": by_diff, "by_gen": by_gen, "by_source": by_source}; }
    for line in p.read_text().split("\n") {
        if line.strip() == "" { continue; }
        rec: dict = dict(json.loads(line));
        meta: dict = dict(rec["meta"]);
        diff: str = str(meta["difficulty"]);
        gen: str = str(meta["generator"]);
        source: str = str(meta["source"]);
        by_diff[diff] = by_diff.get(diff, 0) + 1;
        by_gen[gen] = by_gen.get(gen, 0) + 1;
        by_source[source] = by_source.get(source, 0) + 1;
        total += 1;
    }
    return {"total": total, "by_diff": by_diff, "by_gen": by_gen, "by_source": by_source};
}


def line_count(path: str) -> int {
    p = Path(path);
    if not p.exists() { return 0; }
    n: int = 0;
    for line in p.read_text().split("\n") { if line.strip() != "" { n += 1; } }
    return n;
}


with entry {
    grand: int = 0;
    print("=== Conversion SFT dataset ===");
    for f in SFT_FILES {
        r: dict = count_file(f);
        t: int = int(r["total"]);
        grand += t;
        print(f + ":  " + str(t));
        print("    by difficulty: " + str(r["by_diff"]));
        print("    by generator:  " + str(r["by_gen"]));
        print("    by source:     " + str(r["by_source"]));
    }
    print("TOTAL SFT examples: " + str(grand));
    print("DPO pairs: " + str(line_count(DPO_FILE)));
}
