"""studio - pure parsers for training/eval artifacts. Ports server/runlogs.py.

Log/metric parsers for the Train/Evals sections: mlx trainer log → chart series,
JSONL point/last-row readers, idiom-summary pickers, stage done-marker scan, and
per-run series merge. Internal helpers consumed by other .sv.jac modules, NOT HTTP
endpoints — plain `def`, no `:pub`.

Checker notes (jaclang 0.16.1): re.Match / json.loads results stay in `any` locals;
`int()/float()` reject `any`, so captured groups and dict values go through
`int(str(...))` / `float(str(...))`; json.loads landing in a typed dict is `dict(...)`.
"""

import json;
import re;
import from pathlib { Path }

def _num(line: str, pattern: str) -> float {
    m: any = re.search(pattern, line);
    if m is None { return -1.0; }
    return float(str(m.group(1)));
}

def _num2(line: str, p1: str, p2: str) -> float {
    v = _num(line, p1);
    if v >= 0.0 { return v; }
    return _num(line, p2);
}

def _pt(it: int, v: float) -> dict {
    return {"x": it, "y": v};
}

"""Parse an mlx trainer log (SFT mlx_lm.lora + DPO formats) into chart series.
Returns {train, val, lr, tps: list[{x,y}], last_iter: int}."""
def parse_train_log(path: Path) -> dict {
    empty = {"train": [], "val": [], "lr": [], "tps": [], "last_iter": 0};
    if not path.exists() { return empty; }
    train: list[dict] = [];
    val: list[dict] = [];
    lr: list[dict] = [];
    tps: list[dict] = [];
    last_it: int = 0;
    for line in path.read_text().split("\n") {
        m: any = re.search(r"Iter (\d+)", line);
        if m is None { continue; }
        it = int(str(m.group(1)));
        if it > last_it { last_it = it; }
        tl = _num2(line, r"Train loss ([0-9.]+)", r": loss ([0-9.]+)");
        if tl >= 0.0 { train.append(_pt(it, tl)); }
        vl = _num(line, r"Val loss ([0-9.]+)");
        if vl >= 0.0 { val.append(_pt(it, vl)); }
        lv = _num2(line, r"Learning Rate ([0-9.eE+-]+)", r" lr ([0-9.eE+-]+)");
        if lv >= 0.0 { lr.append(_pt(it, lv)); }
        tv = _num2(line, r"Tokens/sec ([0-9.]+)", r"tok/s ([0-9.]+)");
        if tv >= 0.0 { tps.append(_pt(it, tv)); }
    }
    return {"train": train, "val": val, "lr": lr, "tps": tps, "last_iter": last_it};
}

"""Read a JSONL file as [{x: step, y: <ykey>}]. Skips non-object / incomplete rows."""
def read_series(path: Path, ykey: str) -> list[dict] {
    out: list[dict] = [];
    if not path.exists() { return out; }
    for line in path.read_text().split("\n") {
        stripped = line.strip();
        if not stripped.startswith("{") { continue; }
        try {
            r = json.loads(stripped);
        } except Exception { continue; }
        if "step" not in r or ykey not in r { continue; }
        out.append(_pt(int(str(r["step"])), float(str(r[ykey]))));
    }
    return out;
}

"""Last parseable JSON object in a JSONL file, or {} if none/missing."""
def last_row(path: Path) -> dict {
    last: dict = {};
    if not path.exists() { return last; }
    for line in path.read_text().split("\n") {
        stripped = line.strip();
        if not stripped.startswith("{") { continue; }
        try {
            last = dict(json.loads(stripped));
        } except Exception { continue; }
    }
    return last;
}

"""Last *n* lines of *path* joined, or "" if missing."""
def tail(path: Path, n: int = 40) -> str {
    if not path.exists() { return ""; }
    lines = path.read_text().split("\n");
    start = max(0, len(lines) - n);
    return "\n".join(lines[start:]);
}

"""Maximum Iter number in *log_path*, or 0 if missing/empty."""
def last_iter(log_path: Path) -> int {
    if not log_path.exists() { return 0; }
    last = 0;
    for m in re.finditer(r"Iter (\d+)", log_path.read_text()) {
        v = int(str(m.group(1)));
        if v > last { last = v; }
    }
    return last;
}

"""Merge per-run [{x,y}] series into overlay rows [{x, <name>: y, ...}], sorted by x."""
def merge_by_x(by_run: dict) -> list {
    rows: dict = {};
    for (name, series) in by_run.items() {
        for pt in list(series) {
            xi = int(str(pt["x"]));
            row = rows.get(xi, {"x": xi});
            row[name] = float(str(pt["y"]));
            rows[xi] = row;
        }
    }
    return [rows[k] for k in sorted(rows)];
}

"""Ordered list of completed stage names (each has a .<stage>.done marker)."""
def stages(run_dir: Path) -> list[str] {
    found: list[str] = [];
    if not run_dir.exists() { return found; }
    for s in ["base", "dry", "train", "curve", "finetuned"] {
        if (run_dir / f".{s}.done").exists() { found.append(s); }
    }
    return found;
}

"""Last-row idiom summary for a holdout kind ("function" | "graph"), or {}."""
def idiom_summary(run_dir: Path, mode: str, kind: str) -> dict {
    base: Path = run_dir;
    if mode == "dpo" { base = run_dir / "dpo"; }
    candidates: list[Path] = [];
    if kind == "function" {
        candidates = [base / "idiom-metrics.jsonl"];
    } else {
        candidates = [base / "graph-idiom-metrics.jsonl", base / "graph-idiom.jsonl"];
    }
    for cand in candidates {
        row = last_row(cand);
        if row and "avg_sim" in row { return row; }
    }
    return {};
}
