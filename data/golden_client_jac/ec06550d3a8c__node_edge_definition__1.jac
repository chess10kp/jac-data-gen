"""studio - eval-run lifecycle (detached jac eval jobs + OSP history).

Ports server/routers/evals.py + server/evalruns.py + the eval_runs CRUD in
server/db.py. Eval runs persist as graph nodes (`root --> EvalRun`), mirroring
persistence.sv.jac; the SQLite `eval_runs` table is replaced by the graph. The
subprocess machinery lives in jobs.sv.jac, the metric/log readers in metrics.sv.jac.

Each run owns an artifacts dir results/_evals/<eid> holding run.log, metrics.jsonl
and a job.json (the jobs-module process tracker). The `__EXIT__` marker in run.log
is authoritative over pid liveness; on a clean exit (code 0) the last metrics.jsonl
row becomes the run's scores.

Checker notes (jaclang 0.16.1): json.loads into a typed dict → dict(json.loads(...));
HOLDOUTS value goes through str(); subprocess pid stays int.
"""

import json;
import os;
import shlex;
import shutil;
import datetime;
import jobs;
import metrics;
import models;
import from pathlib { Path }
import from uuid { uuid4 }

glob VALID_KINDS: list[str] = ["probe", "idiom"];

def _now() -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

"""One eval run as the client sees it: registry metadata + resolved scores + tail."""
obj EvalView {
    has id: str = "",
        kind: str = "",
        model: str = "",
        adapter: str = "",
        holdout: str = "",
        params: dict = {},
        pid: int = 0,
        scores: dict = {},
        status: str = "",
        started: str = "",
        finished: str = "",
        log_tail: str = "";
}

node EvalRun {
    has eid: str = "",
        kind: str = "",
        model: str = "",
        adapter: str = "",
        holdout: str = "",
        params_json: str = "",
        pid: int = 0,
        scores_json: str = "",
        status: str = "running",
        started: str = "",
        finished: str = "";

    def to_view(log_tail: str) -> EvalView {
        sc: dict = {};
        if self.scores_json {
            sc = dict(json.loads(self.scores_json));
        }
        pa: dict = {};
        if self.params_json {
            pa = dict(json.loads(self.params_json));
        }
        return EvalView(
            id=self.eid, kind=self.kind, model=self.model, adapter=self.adapter,
            holdout=self.holdout, params=pa, pid=self.pid, scores=sc,
            status=self.status, started=self.started, finished=self.finished,
            log_tail=log_tail
        );
    }
}

"""Return (and create) the artifacts dir for *eid*."""
def eval_dir(eid: str) -> Path {
    d = models.results_dir() / "_evals" / eid;
    d.mkdir(parents=True, exist_ok=True);
    return d;
}

def _find(eval_id: str) -> EvalRun | None {
    for r in [root -->][?:EvalRun] {
        if r.eid == eval_id {
            return r;
        }
    }
    return None;
}

"""Spawn the detached eval job for *run*; returns the child pid. Builds env exactly
like evalruns.start (JAC_EVAL_MODE=mlx, model/holdout/adapter, probe→eval_probe.jac
with metrics-out+step, idiom→idiom_eval.jac with idiom-out+sim)."""
def _start(run: EvalRun, limit: int, sim_threshold: float) -> int {
    ed = eval_dir(run.eid);
    run_log = ed / "run.log";
    metrics_out = ed / "metrics.jsonl";

    venv_bin = str(models.data_root() / ".venv" / "bin");
    current_path = os.environ.get("PATH", "");
    env: dict = {
        "JAC_EVAL_MODE": "mlx",
        "JAC_EVAL_MODEL": run.model,
        "JAC_HOLDOUT": str(models.data_root() / str(models.HOLDOUTS[run.holdout])),
        "PATH": f"{venv_bin}:{current_path}"
    };
    if run.adapter {
        env["JAC_EVAL_ADAPTER"] = run.adapter;
    }

    script = "";
    if run.kind == "probe" {
        env["JAC_EVAL_METRICS_OUT"] = str(metrics_out);
        env["JAC_EVAL_STEP"] = "0";
        if limit > 0 { env["JAC_EVAL_LIMIT"] = str(limit); }
        script = "eval_probe.jac";
    } else {
        env["JAC_IDIOM_OUT"] = str(metrics_out);
        if sim_threshold > 0.0 { env["JAC_IDIOM_SIM"] = str(sim_threshold); }
        if limit > 0 { env["JAC_EVAL_LIMIT"] = str(limit); }
        script = "idiom_eval.jac";
    }

    inner = f"{shlex.quote(str(models.jac_bin()))} run model-experiments/01-sft-dpo/sft_dpo/jacgen/{script}";
    job = jobs.launch(ed / "job.json", run_log, inner, env, models.data_root(), {"eid": run.eid});
    return int(str(job.get("pid") or 0));
}

"""Refresh a running run's status (live_status-style): resolve the job.json/run.log
via jobs.live_status, then on a clean exit read metrics.jsonl last_row for scores.
Mutates and persists the node. No-op on terminal runs."""
def _refresh(run: EvalRun) -> None {
    if run.status != "running" { return; }
    ed = eval_dir(run.eid);
    job = jobs.live_status(ed / "job.json", ed / "run.log");
    if job is None {
        # Artifacts dir gone (legacy DataGeneration-era eval or manual cleanup):
        # resolve the node instead of leaving it "running" forever.
        run.status = "stopped";
        run.finished = _now();
        return;
    }
    st = str(job.get("status", "running"));
    if st == "running" { return; }
    if st == "done" {
        scores = metrics.last_row(ed / "metrics.jsonl");
        if scores {
            run.status = "done";
            run.scores_json = json.dumps(scores);
        } else {
            run.status = "failed";
        }
    } else {
        run.status = st;
    }
    run.finished = _now();
}

"""Create + launch an eval run. Resolves the model from *model_id* (must be a known,
on-disk model) or *model_path* (sandboxed to data root); *adapter* is optional. A
limit of 0 / sim_threshold of 0.0 means "unset". Returns the run (no log_tail) or
None on a validation failure."""
def:pub create_eval(
    kind: str,
    model_id: str = "",
    model_path: str = "",
    adapter: str = "",
    holdout: str = "function",
    limit: int = 0,
    sim_threshold: float = 0.0
) -> EvalView | None {
    if kind not in VALID_KINDS { return None; }
    if holdout not in models.HOLDOUTS { return None; }

    model_rel = "";
    if model_path {
        if not jobs.safe(model_path, True) { return None; }
        model_rel = model_path;
    } elif model_id {
        m = models.model_by_id(model_id);
        if not m { return None; }
        if not models.model_available(m) { return None; }
        model_rel = str(m["path"]);
    } else {
        return None;
    }

    adapter_rel = "";
    if adapter {
        if not jobs.safe(adapter, True) { return None; }
        adapter_rel = adapter;
    }

    params: dict = {};
    if limit > 0 { params["limit"] = limit; }
    if sim_threshold > 0.0 { params["sim_threshold"] = sim_threshold; }

    eid = uuid4().hex[:12];
    ed = eval_dir(eid);
    grab = jobs.heavy_acquire(f"eval:{eid}", ed / "job.json", ed / "run.log");
    if not grab["ok"] { return None; }

    run = (root ++> EvalRun(
        eid=eid, kind=kind, model=model_rel, adapter=adapter_rel,
        holdout=holdout, params_json=json.dumps(params), status="running",
        started=_now()
    ))[0];
    run.pid = _start(run, limit, sim_threshold);
    return run.to_view("");
}

"""All eval runs, newest-first, each refreshed. Mirrors `ORDER BY id DESC`."""
def:pub list_evals() -> dict {
    out: list[EvalView] = [];
    for r in [root -->][?:EvalRun] {
        _refresh(r);
        out.append(r.to_view(""));
    }
    out.sort(key=lambda v: EvalView -> str { return v.started; }, reverse=True);
    return {"evals": out};
}

"""One eval run with the last 60 run.log lines (refreshed). None if unknown."""
def:pub get_eval(eval_id: str) -> EvalView | None {
    run = _find(eval_id);
    if run is None { return None; }
    _refresh(run);
    tail = metrics.tail(eval_dir(run.eid) / "run.log", 60);
    return run.to_view(tail);
}

"""Kill a running eval (jobs.stop) and mark it stopped. None if unknown."""
def:pub stop_eval(eval_id: str) -> EvalView | None {
    run = _find(eval_id);
    if run is None { return None; }
    if run.status == "running" {
        ed = eval_dir(run.eid);
        jobs.stop(ed / "job.json", ed / "run.log");
        run.status = "stopped";
        run.finished = _now();
    }
    return run.to_view("");
}

"""Stop if running, then delete the node and its artifacts dir. False if unknown."""
def:pub delete_eval(eval_id: str) -> bool {
    run = _find(eval_id);
    if run is None { return False; }
    eid = run.eid;
    if run.status == "running" {
        ed = eval_dir(eid);
        jobs.stop(ed / "job.json", ed / "run.log");
    }
    del run;
    shutil.rmtree(str(models.results_dir() / "_evals" / eid), ignore_errors=True);
    return True;
}
