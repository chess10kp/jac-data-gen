"""Build a balanced training manifest (de-skew idiomatic vs transpile).

The raw pool is ~1:14 idiomatic:transpile, which would teach Python-shaped Jac.
This writes 01-sft-dpo/dataset/conversion/sft_train.jsonl = ALL idiomatic core + a
deterministic stride-sample of the transpile tier capped at RATIO x idiomatic.
The finetune trains on sft_train.jsonl; the full sft_auto.jsonl is retained.

Run from the repo root:
    jac run srccurrent/jacgen/build_manifest.jac
"""

import from pathlib { Path }

glob IDIOMATIC: str = "01-sft-dpo/dataset/conversion/sft.jsonl";
glob TRANSPILE: str = "01-sft-dpo/dataset/conversion/sft_auto.jsonl";
glob OUT: str = "01-sft-dpo/dataset/conversion/sft_train.jsonl";
glob RATIO: int = 2;  # transpile examples per idiomatic example (idiomatic core tripled to 420, was 3 at 147)


def read_lines(path: str) -> list[str] {
    p = Path(path);
    if not p.exists() { return []; }
    out: list[str] = [];
    for line in p.read_text().split("\n") {
        if line.strip() != "" { out.append(line); }
    }
    return out;
}


with entry {
    idi: list[str] = read_lines(IDIOMATIC);
    tra: list[str] = read_lines(TRANSPILE);
    n_idi: int = len(idi);
    want: int = n_idi * RATIO;

    sampled: list[str] = [];
    if len(tra) <= want {
        sampled = tra;
    } else {
        stride: int = len(tra) // want;
        i: int = 0;
        while i < len(tra) and len(sampled) < want {
            sampled.append(tra[i]);
            i += stride;
        }
    }

    Path(OUT).parent.mkdir(parents=True, exist_ok=True);
    with open(OUT, "w") as f {
        for line in idi { f.write(line + "\n"); }
        for line in sampled { f.write(line + "\n"); }
    }

    total: int = n_idi + len(sampled);
    rat: int = len(sampled) // n_idi;
    print("manifest: " + str(n_idi) + " idiomatic + " + str(len(sampled))
        + " transpile (sampled from " + str(len(tra)) + ") = " + str(total));
    print("idiomatic:transpile ratio = 1:" + str(rat) + "  -> " + OUT);
}
