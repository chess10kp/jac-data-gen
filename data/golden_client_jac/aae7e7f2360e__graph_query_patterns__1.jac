"""Render training graphs as PNGs (matplotlib).

SCAFFOLD — needs `pip install matplotlib` in your jac Python env. Parses the
mlx_lm.lora training log + the per-checkpoint learning-curve metrics and writes
01-sft-dpo/results/*.png: train loss, val loss, learning rate, tokens/sec, and the holdout
test-pass learning curve. The zero-dep ASCII view is dashboard.jac.

    JAC_TRAIN_LOG=01-sft-dpo/results/x-train.log JAC_METRICS=01-sft-dpo/results/x-metrics.jsonl \
        jac run srccurrent/jacgen/plot_metrics.jac
"""

import json;
import re;
import os;
import matplotlib;
import from matplotlib { pyplot }
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


def plot_one(points: list, title: str, ylabel: str, outpath: str) {
    if len(points) == 0 { return; }
    xs: list = [p[0] for p in points];
    ys: list = [p[1] for p in points];
    pyplot.figure();  # jac:ignore[E1051]
    pyplot.plot(xs, ys, marker="o");  # jac:ignore[E1051,E1052]
    pyplot.title(title);  # jac:ignore[E1051]
    pyplot.xlabel("iteration");  # jac:ignore[E1051]
    pyplot.ylabel(ylabel);  # jac:ignore[E1051]
    pyplot.grid(True);  # jac:ignore[E1051]
    pyplot.savefig(outpath);  # jac:ignore[E1051]
    pyplot.close();  # jac:ignore[E1051]
    print("  wrote " + outpath);
}


with entry {
    matplotlib.use("Agg");
    train_log: str = os.environ.get("JAC_TRAIN_LOG", "01-sft-dpo/results/train.log");
    metrics: str = os.environ.get("JAC_METRICS", "01-sft-dpo/results/metrics.jsonl");
    d: str = os.environ.get("JAC_PLOT_DIR", "results");   # per-model output dir (e.g. 01-sft-dpo/results/qwen)

    t: dict = parse_train(train_log);
    plot_one(list(t["train"]), "Train Loss", "loss", d + "/train_loss.png");
    plot_one(list(t["val"]), "Validation Loss", "loss", d + "/val_loss.png");
    plot_one(list(t["lr"]), "Learning Rate", "lr", d + "/learning_rate.png");
    plot_one(list(t["tps"]), "Throughput", "tokens/sec", d + "/tokens_per_sec.png");
    plot_one(list(t["itsec"]), "Iterations/sec", "it/sec", d + "/iters_per_sec.png");
    plot_one(list(t["trained"]), "Trained Tokens (cumulative)", "tokens", d + "/trained_tokens.png");
    plot_one(list(t["peak"]), "Peak Memory", "GB", d + "/peak_mem.png");

    lc: list = [];
    mp = Path(metrics);
    if mp.exists() {
        for line in mp.read_text().split("\n") {
            if not line.strip().startswith("{") { continue; }   # skip blank/partial lines
            r: dict = dict(json.loads(line));
            lc.append([r["step"], r["test_pass_pct"]]);
        }
    }
    plot_one(lc, "Holdout test-pass % per checkpoint (learning curve)", "test-pass %",
             d + "/learning_curve.png");
    print("graphs in " + d + "/");
}
