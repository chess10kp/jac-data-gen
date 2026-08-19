"""Zero-dependency ASCII training dashboard (no matplotlib needed).

Parses the mlx_lm.lora training log (01-sft-dpo/results/<name>-train.log) for train/val
loss, learning rate, tokens/sec, and the per-checkpoint learning-curve metrics
(01-sft-dpo/results/<name>-metrics.jsonl from eval_probe), and renders terminal charts.
run_probe.sh re-runs this on a timer for a live view.

    jac run srccurrent/jacgen/dashboard.jac
Override paths via env JAC_TRAIN_LOG / JAC_METRICS.
"""

import json;
import re;
import os;
import from pathlib { Path }
import from typing { Any }


def _num(line: str, pattern: str) -> float {
    m = re.search(pattern, line);
    if m is None { return -1.0; }
    return float(str(m.group(1)));
}


def parse_train(path: str) -> dict {
    train: list = [];
    val: list = [];
    lr: list = [];
    tps: list = [];
    itsec: list = [];
    trained: list = [];
    peak: list = [];
    p = Path(path);
    if not p.exists() {
        return {"train": train, "val": val, "lr": lr, "tps": tps,
                "itsec": itsec, "trained": trained, "peak": peak};
    }
    for line in p.read_text().split("\n") {
        m = re.search("Iter (\\d+)", line);
        if m is None { continue; }
        it: int = int(str(m.group(1)));
        tl: float = _num(line, "Train loss ([0-9.]+)");
        if tl >= 0.0 { train.append([it, tl]); }
        vl: float = _num(line, "Val loss ([0-9.]+)");
        if vl >= 0.0 { val.append([it, vl]); }
        lv: float = _num(line, "Learning Rate ([0-9.eE+-]+)");
        if lv >= 0.0 { lr.append([it, lv]); }
        tv: float = _num(line, "Tokens/sec ([0-9.]+)");
        if tv >= 0.0 { tps.append([it, tv]); }
        iv: float = _num(line, "It/sec ([0-9.]+)");
        if iv >= 0.0 { itsec.append([it, iv]); }
        ttv: float = _num(line, "Trained Tokens ([0-9]+)");
        if ttv >= 0.0 { trained.append([it, ttv]); }
        pv: float = _num(line, "Peak mem ([0-9.]+)");
        if pv >= 0.0 { peak.append([it, pv]); }
    }
    return {"train": train, "val": val, "lr": lr, "tps": tps,
            "itsec": itsec, "trained": trained, "peak": peak};
}


def bar(value: float, lo: float, hi: float, width: int) -> str {
    if hi <= lo { return "#"; }
    n: int = int((value - lo) / (hi - lo) * width);
    out: str = "";
    for _ in range(n) { out += "#"; }
    return out;
}


def render(label: str, points: list) {
    if len(points) == 0 {
        print("--- " + label + ": (no data yet) ---");
        return;
    }
    lo: float = float(str(points[0][1]));
    hi: float = float(str(points[0][1]));
    for pt in points {
        v: float = float(str(pt[1]));
        if v < lo { lo = v; }
        if v > hi { hi = v; }
    }
    print("--- " + label + "  [min " + str(lo) + ", max " + str(hi) + "] ---");
    start: int = 0;
    if len(points) > 12 { start = len(points) - 12; }
    for i in range(start, len(points)) {
        pt = points[i];
        print("  " + str(pt[0]) + "\t" + str(pt[1]) + "\t" + bar(float(str(pt[1])), lo, hi, 28));
    }
}


with entry {
    train_log: str = os.environ.get("JAC_TRAIN_LOG", "01-sft-dpo/results/train.log");
    metrics: str = os.environ.get("JAC_METRICS", "01-sft-dpo/results/metrics.jsonl");

    t: dict = parse_train(train_log);
    print("==================== TRAINING DASHBOARD ====================");
    render("train loss", list(t["train"]));
    render("val loss", list(t["val"]));
    render("learning rate", list(t["lr"]));
    render("tokens/sec", list(t["tps"]));
    render("iters/sec", list(t["itsec"]));
    render("trained tokens (cumulative)", list(t["trained"]));
    render("peak mem (GB)", list(t["peak"]));

    lc: list = [];
    mp = Path(metrics);
    if mp.exists() {
        for line in mp.read_text().split("\n") {
            if not line.strip().startswith("{") { continue; }   # skip blank/partial lines
            r: dict = dict(json.loads(line));
            lc.append([r["step"], r["test_pass_pct"]]);
        }
    }
    print("");
    render("HOLDOUT test-pass % per checkpoint (LEARNING CURVE)", lc);
    print("============================================================");
}
