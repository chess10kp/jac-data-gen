"""studio - read-only training-run metrics. Ports server/routers/runs.py.

`def:pub` HTTP endpoints surfacing parsed training artifacts for the Train
HISTORY / MONITOR views: full per-run RunMetrics (loss/val/lr/tps + accuracy curve
+ idiom holdouts + log tail), run listing, and the cross-run compare overlay. All
parsing lives in metrics.sv.jac (runlogs.py); liveness in jobs.sv.jac (procs.py).

Checker notes (jaclang 0.16.1): metrics.parse_train_log returns a dict of `any`
series — pass straight through into the response dict (never re-type); dict values
are `any`, so float/int casts go via `float(str(...))` / `int(str(...))`;
live_status returns dict|None → guard None.
"""

import jobs;
import metrics;
import models;
import from pathlib { Path }

def _run_dir(name: str) -> Path {
    return models.results_dir() / name;
}

def _f(d: dict, k: str) -> float {
    return float(str(d.get(k, 0.0)));
}

def _i(d: dict, k: str) -> int {
    return int(str(d.get(k, 0)));
}

"""True if either the SFT or DPO job file shows status "running"."""
def _is_running(name: str) -> bool {
    for mode in ["sft", "dpo"] {
        jf = models.results_dir() / name / f".job-{mode}.json";
        runlog = models.results_dir() / name / f"run-{mode}.log";
        job = jobs.live_status(jf, runlog);
        if job is not None and str(job.get("status")) == "running" { return True; }
    }
    return False;
}

"""Best idiom-metrics file for (run_dir, mode) — prefers function holdout over graph,
accepts only files whose last row carries "avg_sim". Ports runlogs.pick_idiom."""
def _pick_idiom(run_dir: Path, mode: str) -> Path | None {
    candidates: list[Path] = [];
    if mode == "dpo" {
        candidates = [run_dir / "dpo" / "idiom-metrics.jsonl", run_dir / "dpo" / "graph-idiom.jsonl"];
    } else {
        candidates = [run_dir / "idiom-metrics.jsonl", run_dir / "graph-idiom.jsonl"];
    }
    for cand in candidates {
        row = metrics.last_row(cand);
        if row and "avg_sim" in row { return cand; }
    }
    return None;
}

def _idiom_obj(s: dict) -> dict {
    return {
        "has": "avg_sim" in s,
        "avg_sim": _f(s, "avg_sim"),
        "idiomatic": _i(s, "idiomatic"),
        "python_shaped": _i(s, "python_shaped"),
        "runs": _i(s, "runs"),
        "total": _i(s, "total")
    };
}

"""Build the full RunMetrics dict for one run. Ports get_run_metrics."""
def _get_run_metrics(name: str, mode: str) -> dict {
    rdir = _run_dir(name);
    curve_path: Path | None = None;
    log: Path = rdir / "train.log";
    if mode == "dpo" {
        log = rdir / "dpo" / "train.log";
    } else {
        curve_path = rdir / "metrics.jsonl";
    }

    idiom_path = _pick_idiom(rdir, mode);
    idiom_label = "";
    if idiom_path is not None {
        if "graph-idiom" in idiom_path.name {
            idiom_label = "graph holdout";
        } else {
            idiom_label = "function holdout";
        }
    }

    t = metrics.parse_train_log(log);
    curve: list = [];
    if curve_path is not None { curve = metrics.read_series(curve_path, "test_pass_pct"); }
    isum: dict = {};
    idiom_sim: list = [];
    if idiom_path is not None {
        isum = metrics.last_row(idiom_path);
        idiom_sim = metrics.read_series(idiom_path, "avg_sim");
    }

    func_sum = metrics.idiom_summary(rdir, mode, "function");
    graph_sum = metrics.idiom_summary(rdir, mode, "graph");

    running = False;
    if mode == "sft" {
        jx = jobs.live_status(rdir / ".job-sft.json", rdir / "run-sft.log");
        running = jx is not None and str(jx.get("status")) == "running";
    } else {
        jx = jobs.live_status(rdir / ".job-dpo.json", rdir / "run-dpo.log");
        running = jx is not None and str(jx.get("status")) == "running";
    }

    return {
        "name": name,
        "mode": mode,
        "found": log.exists(),
        "running": running,
        "last_iter": t["last_iter"],
        "train": t["train"],
        "val": t["val"],
        "lr": t["lr"],
        "tps": t["tps"],
        "curve": curve,
        "idiom_sim": idiom_sim,
        "has_idiom": "avg_sim" in isum,
        "idiom_label": idiom_label,
        "idiom_avg_sim": _f(isum, "avg_sim"),
        "idiom_idiomatic": _i(isum, "idiomatic"),
        "idiom_python": _i(isum, "python_shaped"),
        "idiom_runs": _i(isum, "runs"),
        "idiom_total": _i(isum, "total"),
        "func_idiom": _idiom_obj(func_sum),
        "graph_idiom": _idiom_obj(graph_sum),
        "log_tail": metrics.tail(log, 40)
    };
}

def _last_y(series: any) -> float {
    s: list = list(series);
    if not s { return 0.0; }
    last = s[len(s) - 1];
    return float(str(last["y"]));
}

"""List all runs with summary info. {"runs": [...]}"""
def:pub list_runs() -> dict {
    base = models.results_dir();
    out: list = [];
    if not base.exists() { return {"runs": out}; }
    for child in sorted(base.iterdir()) {
        if not child.is_dir() { continue; }
        if child.name in models.EXCLUDED_RUN_DIRS { continue; }
        rdir = child;
        has_sft = (rdir / "train.log").exists() or (rdir / ".train.done").exists();
        has_dpo = (rdir / "dpo").exists();
        out.append({
            "name": child.name,
            "has_sft": has_sft,
            "has_dpo": has_dpo,
            "stages": metrics.stages(rdir),
            "running": _is_running(child.name)
        });
    }
    return {"runs": out};
}

"""Full RunMetrics for one run."""
def:pub get_run(name: str, mode: str = "sft") -> dict {
    if not jobs.safe(name) { raise ValueError("invalid run name"); }
    if mode != "sft" and mode != "dpo" { raise ValueError("mode must be sft|dpo"); }
    return _get_run_metrics(name, mode);
}

"""Overlay every run's curves for the given mode + per-run headline numbers."""
def:pub compare_runs(mode: str = "sft") -> dict {
    if mode != "sft" and mode != "dpo" { raise ValueError("mode must be sft|dpo"); }
    base = models.results_dir();
    names: list = [];
    trains: dict = {};
    vals: dict = {};
    curves: dict = {};
    headline: list = [];
    if base.exists() {
        for child in sorted(base.iterdir()) {
            if not child.is_dir() { continue; }
            if child.name in models.EXCLUDED_RUN_DIRS { continue; }
            m = _get_run_metrics(child.name, mode);
            if not m["found"] { continue; }
            name = child.name;
            names.append(name);
            trains[name] = m["train"];
            vals[name] = m["val"];
            curves[name] = m["curve"];
            headline.append({
                "name": name,
                "final_pass": _last_y(m["curve"]),
                "last_loss": _last_y(m["train"]),
                "idiom_sim": m["idiom_avg_sim"],
                "idiomatic": m["idiom_idiomatic"],
                "idiom_label": m["idiom_label"],
                "has_idiom": m["has_idiom"],
                "func_idiom": m["func_idiom"],
                "graph_idiom": m["graph_idiom"],
                "last_iter": m["last_iter"]
            });
        }
    }
    return {
        "names": names,
        "train": metrics.merge_by_x(trains),
        "val": metrics.merge_by_x(vals),
        "curve": metrics.merge_by_x(curves),
        "headline": headline
    };
}
