"""studio - CPT corpus browser + training control (model-experiments/03-new attempt).

Surfaces the continual-pretrain dataset built by model-experiments/03-new/cpt_build/build_cpt.py:
manifest stats (pivoted server-side into chart-ready lists) + per-source raw/packed
row previews. Like rl.sv.jac, CPT data lives in THIS repo (jac_ml_studio), not the
studio's data_root (which can point at the DataGeneration checkout), so paths resolve
against the repo root from __file__ — NOT models.data_root().

Training control mirrors train.sv.jac/runs.sv.jac (jobs.sv.jac for detached-process
lifecycle, metrics.sv.jac for log parsing) but scoped to model-experiments/03-new's own results/adapters
dirs instead of models.results_dir() -- CPT is LoRA continual pretrain on raw text via
mlx_lm.lora directly (no run_probe.sh wrapper: no quantize/base-eval/fuse stages, CPT
has no task-based holdout to eval against yet, see workflow.md's CF-guard open item).
"""

import os;
import json;
import shlex;
import jobs;
import metrics;
import from pathlib { Path }
import from data { FileRefView, DataRowView }

# studio/ sits directly at repo root (post Jul-10 flatten), so the repo root is
# two dirnames up from studio/cpt.sv.jac.
glob CPT_ROOT: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)));

# Preview-allowed CPT files: 5 raw per-source + 2 packed splits.
glob CPT_FILES: list[list[str]] = [
    ["model-experiments/03-new/dataset/cpt/docs/raw.jsonl", "docs · raw"],
    ["model-experiments/03-new/dataset/cpt/code/raw.jsonl", "code · raw"],
    ["model-experiments/03-new/dataset/cpt/blogs/raw.jsonl", "blogs · raw"],
    ["model-experiments/03-new/dataset/cpt/osp_paper/raw.jsonl", "osp_paper · raw"],
    ["model-experiments/03-new/dataset/cpt/rehearsal/raw.jsonl", "rehearsal · raw"],
    ["model-experiments/03-new/dataset/cpt/packed/train.jsonl", "packed · train"],
    ["model-experiments/03-new/dataset/cpt/packed/valid.jsonl", "packed · valid"]
];
glob MANIFEST_REL: str = "model-experiments/03-new/dataset/cpt/manifest.json";
# Source order for the composition bar + stat tiles (largest first).
glob SRC_ORDER: list[str] = ["docs", "code", "rehearsal", "blogs", "osp_paper"];
# meta.type -> short kind label for the row browser.
glob KIND_MAP: dict = {
    "official_doc": "doc", "llm_doc": "doc",
    "paper_section": "paper", "paper_listing": "paper",
    "blog_post": "blog", "repo_file": "code", "repo_pack": "code",
    "general_code": "rehearsal"
};

def _abs(rel: str) -> Path {
    return Path(CPT_ROOT) / rel;
}

def _allowed(rel: str) -> bool {
    for pair in CPT_FILES {
        if pair[0] == rel { return True; }
    }
    return False;
}

def _read_lines(rel: str) -> list {
    p = _abs(rel);
    if not p.exists() { return []; }
    out: list = [];
    for line in p.read_text().split("\n") {
        if line.strip() { out.append(line); }
    }
    return out;
}

def _first_line(s: str) -> str {
    for ln in s.split("\n") {
        t = ln.strip();
        if t {
            return (t[:90] + "…") if len(t) > 90 else t;
        }
    }
    return "";
}

def _row_name(meta: dict, idx: int) -> str {
    f = str(meta.get("file", ""));
    if f { return f; }
    rp = str(meta.get("path", ""));
    if rp {
        repo = str(meta.get("repo", ""));
        base = repo.split("/")[-1] if repo else "";
        return (base + "/" + rp) if base else rp;
    }
    w = meta.get("window", None);
    if w is not None {
        return str(meta.get("source", "pack")) + " #" + str(w);
    }
    return "row " + str(idx);
}

def _build_row(idx: int, rec: any) -> DataRowView {
    meta = rec.get("meta", {});
    src = str(meta.get("source", "—"));
    typ = str(meta.get("type", ""));
    kind = str(KIND_MAP.get(typ, src));
    text = str(rec.get("text", ""));
    diff = "";
    uw = meta.get("upsample_weight", None);
    if uw is not None { diff = str(uw) + "x"; }
    return DataRowView(
        idx=idx, name=_row_name(meta, idx), difficulty=diff or "—",
        source=src, kind=kind, preview=_first_line(text), raw=text
    );
}

"""Manifest pivoted into chart-ready lists so the client never parses JSON/regex.

Returns: sources (ordered [{name, rows, tokens, windows, pct}]), totals, gate
([{repo, files, passed, pct}] sorted by files desc), decontam ([{source, dropped}]),
packed {train, valid}, and passthrough scalars (seq_len, split, tokenizer, eos, fim)."""
def:pub cpt_manifest() -> dict {
    p = _abs(MANIFEST_REL);
    if not p.exists() {
        return {"ok": False};
    }
    m: dict = {};
    try { m = json.loads(p.read_text()); } except Exception { return {"ok": False}; }

    src_raw = m.get("sources", {});
    total_tokens = 0;
    for k in src_raw { total_tokens += int(src_raw[k].get("tokens", 0)); }
    sources: list = [];
    for name in SRC_ORDER {
        if name in src_raw {
            s = src_raw[name];
            tok = int(s.get("tokens", 0));
            pct = (tok * 1000) // total_tokens if total_tokens > 0 else 0;
            sources.append({
                "name": name, "rows": int(s.get("rows", 0)),
                "tokens": tok, "windows": int(s.get("windows", 0)),
                "pct": pct  # per-mille (0-1000) so the client avoids float math
            });
        }
    }

    gate_raw = m.get("code_gate", {});
    gate: list = [];
    for repo in gate_raw {
        g = gate_raw[repo];
        files = int(g.get("files", 0));
        passed = int(g.get("passed", 0));
        pctp = (passed * 100) // files if files > 0 else 0;
        gate.append({"repo": repo, "files": files, "passed": passed, "pct": pctp});
    }
    gate.sort(key=lambda d: dict -> int { return int(d["files"]); }, reverse=True);

    decon_raw = m.get("decontam", {});
    decontam: list = [];
    for s2 in decon_raw {
        decontam.append({"source": s2, "dropped": int(decon_raw[s2])});
    }

    packed = m.get("packed", {});
    return {
        "ok": True,
        "sources": sources,
        "total_tokens": total_tokens,
        "gate": gate,
        "decontam": decontam,
        "packed": {"train": int(packed.get("train", 0)), "valid": int(packed.get("val", 0))},
        "seq_len": int(m.get("seq_len", 0)),
        "split": str(m.get("split", "")),
        "tokenizer": str(m.get("tokenizer", "")),
        "eos_token": str(m.get("eos_token", "")),
        "n_repos": len(m.get("repos", {}))
    };
}

"""All preview-allowed CPT files with line counts."""
def:pub cpt_files() -> list[FileRefView] {
    out: list[FileRefView] = [];
    for pair in CPT_FILES {
        out.append(FileRefView(path=pair[0], label=pair[1], count=len(_read_lines(pair[0]))));
    }
    return out;
}

"""A page of parsed rows from a CPT jsonl (cap 40), gated by the allowlist."""
def:pub cpt_rows(path: str, offset: int, limit: int) -> dict {
    if not _allowed(path) {
        return {"rows": [], "total": 0};
    }
    cap = max(1, min(limit, 40));
    lines = _read_lines(path);
    total = len(lines);
    result: list[DataRowView] = [];
    i = offset;
    while i < total and i < offset + cap {
        try {
            rec = json.loads(str(lines[i]));
            result.append(_build_row(i, rec));
        } except Exception {}
        i += 1;
    }
    return {"rows": result, "total": total};
}


# ---------------------------------------------------------- training control

glob CPT_CONFIGS: dict = {
    "cpt-v1": "model-experiments/03-new/cpt_train/config.yaml"
};
glob CPT_TOTAL_ITERS: dict = {
    "cpt-v1": 2586  # 3 epochs
};

# CPT-v2's multi-leg epoch loop (Tasks 8-10): per-leg configs live in
# CPT_LEG_CONFIG_DIR as config_v2_leg{N}.yaml, and CPT_LEG_CEILING caps how
# many legs (epochs) a run name is allowed to advance through.
glob CPT_LEG_CONFIG_DIR: str = "model-experiments/03-new/cpt_train";
glob CPT_LEG_CEILING: dict = {"cpt-v2": 12};

def _cpt_results_dir(name: str) -> Path {
    return Path(CPT_ROOT) / "model-experiments/03-new" / "results" / name;
}

def _cpt_adapter_dir(name: str) -> Path {
    return Path(CPT_ROOT) / "model-experiments/03-new" / "adapters" / name;
}

def _cpt_job_file(name: str) -> Path {
    return _cpt_results_dir(name) / ".job-cpt.json";
}

def _cpt_run_log(name: str) -> Path {
    return _cpt_results_dir(name) / "run-cpt.log";
}

def _cpt_train_log(name: str) -> Path {
    return _cpt_results_dir(name) / "train.log";
}

"""Latest saved checkpoint + the CUMULATIVE step it represents. mlx_lm restarts
its checkpoint numbering at 1 on every invocation (verified in
mlx_lm/tuner/trainer.py), so the zero-padded prefix alone under-counts after a
resume: cumulative = the job file's resumed_from (steps done before the current
invocation launched) + the prefix of the newest file BY MTIME (digit-max picks
stale big-numbered files from an earlier, longer invocation). Runs resumed
manually outside the studio have no job record and fall back to prefix-only."""
def _cpt_resume_point(name: str) -> dict {
    adir = _cpt_adapter_dir(name);
    if not adir.exists() {
        return {"done_steps": 0, "ckpt": ""};
    }
    ckpts = list(adir.glob("*_adapters.safetensors"));
    if not ckpts {
        return {"done_steps": 0, "ckpt": ""};
    }
    latest = sorted(ckpts, key=lambda p: Path -> float { return p.stat().st_mtime; })[-1];
    digits = "";
    for ch in latest.name {
        if ch.isdigit() { digits += ch; } else { break; }
    }
    steps = int(digits) if digits else 0;
    job = jobs.read_job(_cpt_job_file(name));
    if job is not None {
        steps += int(str(job.get("resumed_from") or 0));
    }
    return {"done_steps": steps, "ckpt": str(latest)};
}

"""Like _cpt_resume_point but for the leg-based CPT-v2 flow: also resolves
the matching optimizer-state file (run_cpt_leg.py writes both files with the
same step prefix, see model-experiments/03-new/docs/cpt-2/design.md section 4.2/Task 8)."""
def _cpt_leg_resume_point(name: str) -> dict {
    base = _cpt_resume_point(name);
    if not base["ckpt"] {
        return {"done_steps": 0, "adapter_ckpt": "", "optimizer_ckpt": ""};
    }
    adapter_ckpt = Path(str(base["ckpt"]));
    opt_ckpt = adapter_ckpt.parent / adapter_ckpt.name.replace("_adapters.safetensors", "_optimizer.safetensors");
    return {
        "done_steps": base["done_steps"],
        "adapter_ckpt": str(adapter_ckpt),
        "optimizer_ckpt": str(opt_ckpt) if opt_ckpt.exists() else ""
    };
}

"""Leg-based runs (names in CPT_LEG_CEILING) derive total_iters from the live
manifest (windows_per_epoch x ceiling_epochs) so status stays correct across
corpus rebuilds; fixed-length runs use the CPT_TOTAL_ITERS table. 0 = corpus
not built yet."""
def _cpt_total_iters(name: str) -> int {
    if name in CPT_LEG_CEILING {
        manifest_path = Path(CPT_ROOT) / "model-experiments/03-new" / "dataset" / name / "manifest.json";
        try {
            m = json.loads(manifest_path.read_text());
            windows = int(str(m["packed"]["train"]));
            ceiling = int(str(CPT_LEG_CEILING[name]));
            return windows * ceiling;
        } except Exception {
            return 0;
        }
    }
    return int(str(CPT_TOTAL_ITERS.get(name, 2586)));
}

def _cpt_build_status(name: str, message: str = "") -> dict {
    jf = _cpt_job_file(name);
    rl = _cpt_run_log(name);
    tl = _cpt_train_log(name);
    job = jobs.live_status(jf, rl);
    parsed = metrics.parse_train_log(tl);
    total_iters = _cpt_total_iters(name);
    leg_ceiling = CPT_LEG_CEILING.get(name, 0);

    if job is None {
        status = "finished" if tl.exists() else "idle";
        return {
            "name": name, "status": status, "pid": 0, "run_id": "", "started": "",
            "last_iter": parsed["last_iter"], "total_iters": total_iters,
            "train": parsed["train"], "val": parsed["val"], "lr": parsed["lr"],
            "tps": parsed["tps"], "log_tail": metrics.tail(rl, 40), "message": message,
            "leg": 0, "leg_ceiling": leg_ceiling
        };
    }
    return {
        "name": name, "status": str(job.get("status", "idle")),
        "pid": int(str(job.get("pid") or 0)), "run_id": str(job.get("run_id", "")),
        "started": str(job.get("started", "")),
        "last_iter": parsed["last_iter"], "total_iters": total_iters,
        "leg": int(str(job.get("leg") or 0)), "leg_ceiling": leg_ceiling,
        "train": parsed["train"], "val": parsed["val"], "lr": parsed["lr"],
        "tps": parsed["tps"], "log_tail": metrics.tail(rl, 40), "message": message
    };
}

"""Start (or resume) a CPT LoRA run via mlx_lm.lora, detached. Resume-aware: if
model-experiments/03-new/adapters/<name> already has checkpoints, only the REMAINING iters run,
picking up from the latest via --resume-adapter-file (same convention as
run_probe.sh). Returns the status dict."""
def:pub start_cpt_training(name: str = "cpt-v1", config: str = "") -> dict {
    if not jobs.safe(name) {
        raise ValueError("invalid name");
    }
    if name not in CPT_CONFIGS and not config {
        raise ValueError(f"no CPT_CONFIGS entry for '{name}' -- pass config= explicitly, "
                          "or use start_cpt_leg() for the multi-leg CPT-v2 flow");
    }

    config_file = CPT_CONFIGS.get(name, CPT_CONFIGS["cpt-v1"]);
    if config { config_file = config; }
    total_iters = CPT_TOTAL_ITERS.get(name, 2586);

    jf = _cpt_job_file(name);
    rl = _cpt_run_log(name);
    existing = jobs.live_status(jf, rl);
    if existing is not None and str(existing.get("status")) == "running" {
        return _cpt_build_status(name, "already running");
    }

    run_dir = _cpt_results_dir(name);
    run_dir.mkdir(parents=True, exist_ok=True);
    adapter_dir = _cpt_adapter_dir(name);
    adapter_dir.parent.mkdir(parents=True, exist_ok=True);

    resume = _cpt_resume_point(name);
    done_steps = int(str(resume["done_steps"]));
    remain = total_iters - done_steps;
    if remain <= 0 {
        return _cpt_build_status(name, f"already complete ({done_steps}/{total_iters})");
    }

    grab = jobs.heavy_acquire(f"cpt:{name}", jf, rl);
    if not grab["ok"] {
        return _cpt_build_status(name, f"busy: {grab['busy_with']} is running");
    }

    tl = _cpt_train_log(name);
    if done_steps == 0 {
        tl.write_text("");  # fresh start clears the learning curve
    }

    venv_bin = str(Path(CPT_ROOT) / ".venv" / "bin");
    env_overrides = {"PATH": f"{venv_bin}:{os.environ.get('PATH', '')}"};

    ckpt = str(resume["ckpt"]);
    resume_flag = f" --resume-adapter-file {shlex.quote(ckpt)}" if ckpt else "";
    # >> not >: a resumed run must append to the existing learning curve (the
    # explicit truncate above already handles the fresh-start case) — matches
    # the leg flow's rule.
    inner = (
        f"mlx_lm.lora --config {shlex.quote(config_file)} "
        f"--adapter-path {shlex.quote(str(adapter_dir))} "
        f"--iters {remain}{resume_flag} "
        f">> {shlex.quote(str(tl))} 2>&1"
    );

    jobs.launch(jf, rl, inner, env_overrides, Path(CPT_ROOT), {
        "name": name, "mode": "cpt",
        "resumed_from": done_steps, "iters_this_run": remain
    });

    msg = "";
    if done_steps > 0 {
        msg = f"training {remain} iters (resuming from {done_steps}/{total_iters})";
    } else {
        msg = f"training {remain} iters from scratch";
    }
    return _cpt_build_status(name, msg);
}

"""Run ONE CPT-v2 leg (one epoch) via run_cpt_leg.py (Task 8), which persists
optimizer state across legs -- unlike start_cpt_training's raw mlx_lm.lora
invocation, which only resumes weights (see design.md section 4.2). Detached
job semantics mirror start_cpt_training exactly (jobs.spawn_detached +
jobs.with_exit_marker), just a different inner command."""
def:pub start_cpt_leg(name: str = "cpt-v2", leg: int = 1) -> dict {
    if not jobs.safe(name) {
        raise ValueError("invalid name");
    }
    ceiling = CPT_LEG_CEILING.get(name, 12);
    if leg < 1 or leg > ceiling {
        raise ValueError(f"leg must be 1..{ceiling}");
    }

    jf = _cpt_job_file(name);
    rl = _cpt_run_log(name);
    existing = jobs.live_status(jf, rl);
    if existing is not None and str(existing.get("status")) == "running" {
        return _cpt_build_status(name, "already running");
    }

    resume = _cpt_leg_resume_point(name);
    done_steps = int(str(resume["done_steps"]));

    manifest_path = Path(CPT_ROOT) / "model-experiments/03-new" / "dataset" / name / "manifest.json";
    windows = 0;
    try {
        m = json.loads(manifest_path.read_text());
        windows = int(m["packed"]["train"]);
    } except Exception {
        raise ValueError(f"{name} manifest.json not found -- build the corpus first (Task 6)");
    }
    expected_done = windows * (leg - 1);
    if done_steps != expected_done {
        raise ValueError(f"resume point ({done_steps} steps) doesn't match leg {leg}'s "
                          f"expected start ({expected_done}) -- legs must run in order");
    }

    grab = jobs.heavy_acquire(f"cpt-leg:{name}", jf, rl);
    if not grab["ok"] {
        return _cpt_build_status(name, f"busy: {grab['busy_with']} is running");
    }

    config_file = str(Path(CPT_LEG_CONFIG_DIR) / f"config_v2_leg{leg}.yaml");
    adapter_dir = _cpt_adapter_dir(name);
    run_dir = _cpt_results_dir(name);
    run_dir.mkdir(parents=True, exist_ok=True);
    adapter_dir.parent.mkdir(parents=True, exist_ok=True);

    tl = _cpt_train_log(name);
    if leg == 1 { tl.write_text(""); }

    venv_bin = str(Path(CPT_ROOT) / ".venv" / "bin");
    env_overrides = {"PATH": f"{venv_bin}:{os.environ.get('PATH', '')}"};

    resume_flags = "";
    if resume["adapter_ckpt"] {
        resume_flags += f" --resume-adapter-file {shlex.quote(str(resume['adapter_ckpt']))}";
    }
    if resume["optimizer_ckpt"] {
        resume_flags += f" --resume-optimizer-file {shlex.quote(str(resume['optimizer_ckpt']))}";
    }

    inner = (
        f"{venv_bin}/python3 model-experiments/03-new/cpt_train/run_cpt_leg.py "
        f"--config {shlex.quote(config_file)} "
        f"--adapter-path {shlex.quote(str(adapter_dir))} "
        f"--iters {windows} --done-steps {done_steps}{resume_flags} "
        f">> {shlex.quote(str(tl))} 2>&1"
    );
    jobs.launch(jf, rl, inner, env_overrides, Path(CPT_ROOT), {
        "name": name, "mode": "cpt-leg", "leg": leg, "resumed_from": done_steps
    });
    return _cpt_build_status(name, f"leg {leg}/{ceiling} running ({windows} iters, resuming from {done_steps})");
}

"""Stop a running CPT job (SIGTERM the process group). When *run_id* is given,
only that exact run is stopped (a newer run is reported superseded). Returns status."""
def:pub stop_cpt_training(name: str = "cpt-v1", run_id: str = "") -> dict {
    if not jobs.safe(name) {
        raise ValueError("invalid name");
    }
    res = jobs.stop(_cpt_job_file(name), _cpt_run_log(name), run_id=run_id);
    if res is not None and str(res.get("status", "")) == "superseded" {
        return _cpt_build_status(name, f"run {run_id} superseded; not stopped");
    }
    return _cpt_build_status(name, "stop signal sent");
}

"""Poll live status + full loss/lr/tps curves for a CPT run."""
def:pub get_cpt_status(name: str = "cpt-v1") -> dict {
    if not jobs.safe(name) {
        raise ValueError("invalid name");
    }
    return _cpt_build_status(name);
}

"""Get status of all CPT runs for comparison view. cpt-v3 was removed from
this design (see Task 12); its stub entry was dropped from CPT_CONFIGS/
CPT_TOTAL_ITERS earlier and is no longer iterated here either. cpt-v2's
total_iters comes from _cpt_total_iters (manifest windows x leg ceiling),
0 if the corpus manifest doesn't exist yet."""
def:pub get_all_cpt_status() -> dict {
    out: dict = {};
    for name in ["cpt-v1", "cpt-v2"] {
        out[name] = _cpt_build_status(name);
    }
    return out;
}
