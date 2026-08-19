import json;
import from pathlib { Path }

glob SRC: str = "01-sft-dpo/dataset/conversion/dpo.jsonl";
glob OUT_DIR: str = "01-sft-dpo/dataset/mlx_dpo";
glob VALID_EVERY: int = 10;

with entry {
    p = Path(SRC);
    lines: list[str] = [];
    for line in p.read_text().split("\n") {
        if line.strip() != "" { lines.append(line); }
    }
    Path(OUT_DIR).mkdir(parents=True, exist_ok=True);
    train: list[str] = [];
    valid: list[str] = [];
    for (i, line) in enumerate(lines) {
        rec: dict = dict(json.loads(line));
        stripped: dict = {"prompt": str(rec["prompt"]), "chosen": str(rec["chosen"]), "rejected": str(rec["rejected"])};
        out: str = json.dumps(stripped);
        if i % VALID_EVERY == 0 { valid.append(out); } else { train.append(out); }
    }
    with open(OUT_DIR + "/train.jsonl", "w") as f { for l in train { f.write(l + "\n"); } }
    with open(OUT_DIR + "/valid.jsonl", "w") as f { for l in valid { f.write(l + "\n"); } }
}
