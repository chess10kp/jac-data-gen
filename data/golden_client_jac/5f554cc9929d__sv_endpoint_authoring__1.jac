"""studio - training job start/stop/status. Ports server/routers/train.py.

`def:pub` HTTP endpoints driving SFT / DPO runs. Detached-process lifecycle lives
in jobs.sv.jac (procs.py); log parsing in metrics.sv.jac (runlogs.py); paths +
registry in models.sv.jac (config.py). Job file:   results_dir()/<name>/.job-<mode>.json
run log:    results_dir()/<name>/run-<mode>.log
train log:  results_dir()/<name>/[dpo/]train.log

Checker notes (jaclang 0.16.1): live_status/read_job return dict|None → guard None;
dict values are `any` so the pid is `int(str(job.get("pid") or 0))` and status/started
go through `str(...)`; EXCLUDED_RUN_DIRS is a list[str] membership test.
"""

import os;
import shlex;
import jobs;
import metrics;
import models;
import from pathlib { Path }

glob SFT_KEYS: list[str] = ["EVAL_EVERY", "SUBSET", "DRY_ITERS", "SKIP_DRY", "LIVE_EVAL"];
glob DPO_KEYS: list[str] = ["DPO_ITERS", "DPO_LR", "DPO_BETA", "DPO_LAYERS", "SUBSET"];

def _job_file(name: str, mode: str) -> Path {
    return models.results_dir() / name / f".job-{mode}.json";
}

def _run_log(name: str, mode: str) -> Path {
    return models.results_dir() / name / f"run-{mode}.log";
}

def _train_log(name: str, mode: str) -> Path {
    if mode == "dpo" {
        return models.results_dir() / name / "dpo" / "train.log";
    }
    return models.results_dir() / name / "train.log";
}

"""Build a JobStatus dict from the job file + live resolution (shape == _build_status)."""
def _build_status(name: str, mode: str, message: str = "") -> dict {
    jf = _job_file(name, mode);
    rl = _run_log(name, mode);
    job = jobs.live_status(jf, rl);
    if job is None {
        tl = _train_log(name, mode);
        status = "finished" if tl.exists() else "idle";
        return {
            "name": name,
            "mode": mode,
            "status": status,
            "pid": 0,
            "run_id": "",
            "started": "",
            "last_iter": metrics.last_iter(tl),
            "log_tail": metrics.tail(rl, 40),
            "message": message
        };
    }
    return {
        "name": name,
        "mode": mode,
        "status": str(job.get("status", "idle")),
        "pid": int(str(job.get("pid") or 0)),
        "run_id": str(job.get("run_id", "")),
        "started": str(job.get("started", "")),
        "last_iter": metrics.last_iter(_train_log(name, mode)),
        "log_tail": metrics.tail(rl, 40),
        "message": message
    };
}

"""Start an SFT or DPO training run (detached). Returns the JobStatus dict."""
def:pub start_training(name: str, mode: str, model_id: str = "", opts: dict = {}) -> dict {
    if not jobs.safe(name) { raise ValueError("invalid name"); }
    if name in models.EXCLUDED_RUN_DIRS { raise ValueError("reserved name"); }
    if mode != "sft" and mode != "dpo" { raise ValueError("mode must be sft|dpo"); }
    if mode == "sft" {
        if not model_id or not jobs.safe(model_id, allow_slash=True) {
            raise ValueError("invalid model_id");
        }
    }

    jf = _job_file(name, mode);
    rl = _run_log(name, mode);
    existing = jobs.live_status(jf, rl);
    if existing is not None and str(existing.get("status")) == "running" {
        return _build_status(name, mode, "already running");
    }

    grab = jobs.heavy_acquire(f"train:{name}:{mode}", jf, rl);
    if not grab["ok"] {
        return _build_status(name, mode, f"busy: {grab['busy_with']} is running");
    }

    run_dir = models.results_dir() / name;
    run_dir.mkdir(parents=True, exist_ok=True);

    keys = SFT_KEYS if mode == "sft" else DPO_KEYS;
    env_overrides: dict = {};
    for k in keys {
        if k in opts {
            val = str(opts[k]);
            if jobs.safe(val) { env_overrides[k] = val; }
        }
    }

    ignored: list = [k for k in opts if k not in keys];
    msg = ("ignored opts: " + ", ".join(sorted(ignored))) if ignored else "started";

    venv_bin = str(models.data_root() / ".venv" / "bin");
    current_path = os.environ.get("PATH", "");
    env_overrides["PATH"] = f"{venv_bin}:{current_path}";

    # The run scripts live in model-experiments/01-sft-dpo/sft_dpo/ (post-flatten layout); they
    # re-cd themselves to the repo root, so cwd=data_root stays correct.
    inner = "";
    if mode == "sft" {
        inner = f"./model-experiments/01-sft-dpo/sft_dpo/run_probe.sh {shlex.quote(model_id)} {shlex.quote(name)}";
    } else {
        inner = f"./model-experiments/01-sft-dpo/sft_dpo/run_dpo.sh {shlex.quote(name)}";
    }

    jobs.launch(jf, rl, inner, env_overrides, models.data_root(), {"name": name, "mode": mode});

    return _build_status(name, mode, msg);
}

"""Stop a running training job (SIGTERM the process group). When *run_id* is
given, only that exact run is stopped — a newer run under the same (name, mode)
is left alone and the message says so. Returns JobStatus."""
def:pub stop_training(name: str, mode: str, run_id: str = "") -> dict {
    if not jobs.safe(name) { raise ValueError("invalid name"); }
    if mode != "sft" and mode != "dpo" { raise ValueError("mode must be sft|dpo"); }
    jf = _job_file(name, mode);
    rl = _run_log(name, mode);
    res = jobs.stop(jf, rl, run_id=run_id);
    if res is not None and str(res.get("status", "")) == "superseded" {
        return _build_status(name, mode, f"run {run_id} superseded; not stopped");
    }
    return _build_status(name, mode, "stop signal sent");
}

"""Poll status for a (name, mode) job. Returns JobStatus."""
def:pub get_status(name: str, mode: str = "sft") -> dict {
    if not jobs.safe(name) { raise ValueError("invalid name"); }
    if mode != "sft" and mode != "dpo" { raise ValueError("mode must be sft|dpo"); }
    return _build_status(name, mode);
}

"""List every training session (SFT + DPO) across all run dirs. {"sessions": [...]}"""
def:pub list_sessions() -> dict {
    base = models.results_dir();
    out: list = [];
    if not base.exists() { return {"sessions": out}; }
    for child in sorted(base.iterdir()) {
        if not child.is_dir() { continue; }
        if child.name in models.EXCLUDED_RUN_DIRS { continue; }
        nm = child.name;
        for mode in ["sft", "dpo"] {
            logp: Path = child / "dpo" / "train.log" if mode == "dpo" else child / "train.log";
            has_log = logp.exists();
            jf = _job_file(nm, mode);
            rl = _run_log(nm, mode);
            job = jobs.live_status(jf, rl);
            if not has_log and job is None { continue; }
            st = "finished";
            if job is not None {
                st = str(job.get("status", "idle"));
                if st == "idle" { st = "finished"; }
            }
            started = str(job.get("started", "")) if job is not None else "";
            out.append({
                "name": nm,
                "mode": mode,
                "status": st,
                "last_iter": metrics.last_iter(logp),
                "started": started,
                "label": f"{nm} · {mode.upper()}"
            });
        }
    }
    return {"sessions": out};
}
