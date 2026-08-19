import json;
import inspect;
import builtins;
import re;
import subprocess;
import from pathlib { Path }
import from typing { Any }

glob DATASET: str = "Vezora/Tested-22k-Python-Alpaca";
glob POOL_PATH: str = "01-sft-dpo/dataset/source_pool/mined.jsonl";
glob ALLOWED_IMPORTS: list[str] = ["math", "re", "string", "functools", "collections", "itertools"];
glob BANNED: list[str] = ["np.", "pd.", "yield", "open(", "input(", "@", "class ", "async ", "lambda", "print(", "self"];
glob INPUTS: list[Any] = ["hello", "Racecar", "abcabc", "level", "Hello World",
                     5, 10, 2, 0, 7, [1, 2, 3, 4], [3, 1, 2], [5, 5, 5],
                     ["a", "b", "a"], [10, 20, 30], [2, 4, 6, 8], 2.5];


def fetch_rows(n: int) -> list[dict] {
    out: list[dict] = [];
    off: int = 0;
    while len(out) < n {
        batch: int = min(100, n - len(out));
        url: str = "https://datasets-server.huggingface.co/rows?dataset=" + DATASET
            + "&config=default&split=train&offset=" + str(off) + "&length=" + str(batch);
        p = subprocess.run(
            ["curl", "-s", "-H", "User-Agent: jacgen", url],
            capture_output=True, text=True, timeout=60
        );
        data: dict = dict(json.loads(p.stdout));
        rows: list = list(data["rows"]);
        if len(rows) == 0 { break; }
        for r in rows {
            row: dict = dict(r["row"]);
            out.append(row);
        }
        off += batch;
    }
    return out;
}


def first_func(code: str) -> str {
    lines: list[str] = code.split("\n");
    start: int = -1;
    for (i, l) in enumerate(lines) {
        if l.startswith("def ") { start = i; break; }
    }
    if start < 0 { return ""; }
    blk: list[str] = [lines[start]];
    for l in lines[start + 1:] {
        if l.strip() == "" or l.startswith(" ") or l.startswith("\t") { blk.append(l); }
        else { break; }
    }
    return "\n".join(blk).rstrip();
}


def is_clean(code: str) -> bool {
    head: str = code.split("\n")[0];
    if "*" in head { return False; }
    for b in BANNED { if b in code { return False; } }
    imports: list = list(re.findall("(?:^\\s*import |^\\s*from )(\\w+)", code, re.M));  # jac:ignore[E1054]
    for m in imports { if m not in ALLOWED_IMPORTS { return False; } }
    if re.search("\\breturn\\s+\\S", code) is None { return False; }
    nlines: int = len(code.split("\n"));
    return nlines > 1 and nlines <= 14;
}


def try_run(code: str) -> dict {
    ns: dict = {};
    try {
        exec(code, {"__builtins__": builtins}, ns);
    } except Exception {  # jac:ignore[W2052] mined code can raise anything
        return {"ok": False};
    }
    funcs: list = [];
    names: list[str] = [];
    for (k, v) in ns.items() {
        if callable(v) and not k.startswith("__") {
            funcs.append(v);
            names.append(str(k));
        }
    }
    if len(funcs) == 0 { return {"ok": False}; }
    fn = funcs[-1];
    name: str = names[-1];
    try {
        params = inspect.signature(fn).parameters;  # jac:ignore[E1053]
        if len(params) != 1 { return {"ok": False}; }
    } except (ValueError, TypeError) {
        return {"ok": False};
    }
    for a in INPUTS {
        try {
            o = fn(a);
        } except Exception {  # jac:ignore[W2052] mined code can raise anything
            continue;
        }
        if o is None { continue; }
        if isinstance(o, (int, float, str, bool, list, dict)) {
            return {"ok": True, "name": name, "input": a, "output": o};
        }
    }
    return {"ok": False};
}


def mine(scan: int, limit: int) -> list[dict] {
    rows: list[dict] = fetch_rows(scan);
    kept: list[dict] = [];
    for r in rows {
        if len(kept) >= limit { break; }
        output: str = str(r["output"]);
        src: str = first_func(output);
        if src == "" or not is_clean(src) { continue; }
        res: dict = try_run(src);
        ok: bool = bool(res["ok"]);
        if not ok { continue; }
        name: str = str(res["name"]);
        call_input = res["input"];
        expected = res["output"];
        kept.append({
            "func_name": name,
            "python": src,
            "call_input": call_input,
            "expected_output": expected,
            "source": DATASET
        });
    }
    return kept;
}


def write_pool(items: list[dict]) {
    p = Path(POOL_PATH);
    p.parent.mkdir(parents=True, exist_ok=True);
    with open(POOL_PATH, "w") as f {
        for it in items { f.write(json.dumps(it) + "\n"); }
    }
}


with entry {
    items: list[dict] = mine(400, 40);
    write_pool(items);
    print("mined " + str(len(items)) + " runnable functions -> " + POOL_PATH);
    for it in items[:10] {
        fname: str = str(it["func_name"]);
        print("  " + fname);
    }
}
