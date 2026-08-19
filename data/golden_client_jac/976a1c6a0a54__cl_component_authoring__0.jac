"""EVALS section — launch form + live run view + history table + model×holdout pivot.

Ports ui/components/sections/evals/{evals-section,eval-launch,eval-run-view,
eval-history,eval-compare}.tsx + lib/use-evals.ts. Eval runs are def:pub functions
on evals.sv.jac (called directly over RPC, not walkers). The active run is polled
every 2.5s while it is running via a setInterval re-armed whenever `current` changes
(dependency effect) — this sidesteps the stale-closure trap of a single mount timer.

Errors render gray (text-foreground), never red — matches the monochrome theme.
"""

sv import from ...evals { create_eval, list_evals, get_eval, stop_eval, delete_eval, EvalView }
sv import from ...models { list_models, ModelView }
import from ..shared.Field { Field, TextInput, Segmented }
import from ..shared.StatusGlyph { StatusGlyph }
import from ..shared.LogView { LogView }
import from ..shared.StatTile { StatTile }
import from ..shared.Button { Button }
import from ..shared.Chip { Chip }
import from ..shared.Gallery { Gallery }

def _stripModels(m: str) -> str {
    if m.startswith("models/") { return m[7:]; }
    return m;
}

def _g(sc: any, k: str) -> str {
    if sc and k in sc { return str(sc[k]); }
    return "·";
}

def _idiomatic(sc: any) -> str {
    if sc and "idiomatic" in sc and "runs" in sc {
        return str(sc["idiomatic"]) + "/" + str(sc["runs"]);
    }
    return "·";
}

# Numeric headline (probe→test_pass_pct, idiom→avg_sim) for best-cell highlight; -1 absent.
def _headNum(r: any) -> float {
    sc: any = r.scores;
    if not sc { return -1.0; }
    key = "test_pass_pct" if str(r.kind) == "probe" else "avg_sim";
    if key in sc { return float(str(sc[key])); }
    return -1.0;
}

# Raw display string of the headline value (preserves the JSON form, e.g. "85").
def _headDisp(r: any) -> str {
    sc: any = r.scores;
    key = "test_pass_pct" if str(r.kind) == "probe" else "avg_sim";
    return str(sc[key]);
}

# String shown in the history SCORE column.
def _headline(r: any) -> str {
    sc: any = r.scores;
    if not sc { return str(r.status); }
    if str(r.kind) == "probe" {
        if "test_pass_pct" in sc { return str(sc["test_pass_pct"]) + "%"; }
        return str(r.status);
    }
    if "avg_sim" in sc { return "sim " + str(sc["avg_sim"]); }
    return str(r.status);
}

# Latest done eval for (model, holdout); `done` is newest-first, so first match wins.
# `done: any` — receives an all-optional props param from _cell (see note there).
def _match(done: any, mdl: any, h: str) -> any {
    for r in done {
        if r.model == mdl and str(r.holdout) == h { return r; }
    }
    return None;
}

def:pub Evals(active: bool = False) -> JsxElement {
    has models: list[ModelView] = [],
        kind: str = "probe",
        modelId: str = "",
        modelPath: str = "",
        adapter: str = "",
        holdout: str = "graph",
        limit: str = "",
        simThreshold: str = "0.7",
        history: list = [],
        current: any = None,
        error: str = "",
        busy: bool = False,
        pollId: any = None;

    async def _refreshList -> None {
        r = await list_evals();
        history = list(r["evals"]);
    }

    async def _poll(cid: str) -> None {
        try {
            d = await get_eval(cid);
        } except Exception { return; }
        if d is None { return; }
        current = d;
        if str(d.status) != "running" {
            await _refreshList();
        }
    }

    async can with entry {
        ms = await list_models();
        models = ms;
        for m in ms {
            if m.available { modelId = m.id; break; }
        }
        await _refreshList();
    }

    # Re-arm the poll timer whenever the active run changes; poll only while the
    # section is visible (hidden sections must not hammer the backend). On
    # re-activation the list refreshes once so a run that finished while hidden
    # resolves immediately.
    async can with [current, active] entry {
        if pollId { clearInterval(float(str(pollId))); pollId = None; }
        if not active { return; }
        await _refreshList();
        c: any = current;
        if c and str(c.status) == "running" {
            cid = str(c.id);
            pollId = setInterval(lambda -> None { _poll(cid); }, 2500);
        }
    }

    can with exit {
        if pollId { clearInterval(float(str(pollId))); }
    }

    async def start -> None {
        busy = True;
        error = "";
        lim = 0;
        if limit.strip() {
            try { lim = int(limit.strip()); } except Exception { lim = 0; }
        }
        sim = 0.0;
        if kind == "idiom" and simThreshold.strip() {
            try { sim = float(simThreshold.strip()); } except Exception { sim = 0.0; }
        }
        mid = "" if modelPath else modelId;
        try {
            rec = await create_eval(
                kind=kind, model_id=mid, model_path=modelPath,
                adapter=adapter, holdout=holdout, limit=lim, sim_threshold=sim
            );
            if rec is None {
                error = "launch failed — check model / path";
            } else {
                d = await get_eval(str(rec.id));
                current = d;
                await _refreshList();
            }
        } except Exception as e {
            error = "launch failed";
        }
        busy = False;
    }

    async def stopActive -> None {
        c: any = current;
        if not c { return; }
        await stop_eval(str(c.id));
        d = await get_eval(str(c.id));
        current = d;
        await _refreshList();
    }

    async def removeEval(id: str) -> None {
        await delete_eval(id);
        c: any = current;
        if c and str(c.id) == id { current = None; }
        await _refreshList();
    }

    async def openEval(id: str) -> None {
        d = await get_eval(id);
        current = d;
    }

    def _launch -> JsxElement {
        avail: list[ModelView] = [];
        for m in models {
            if m.available { avail.append(m); }
        }
        return <div className="relative rounded-md border border-border bg-card p-4 pt-5">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">LAUNCH</span>
            <div className="flex flex-col gap-4">
                <Field label="KIND">
                    <div className="flex flex-col gap-1">
                        <Segmented options={["probe", "idiom"]} value={kind} onSet={lambda v: str { kind = v; }} />
                        <span className="stat-line text-muted-foreground/70">{
                            "behavioral test-pass on holdout" if kind == "probe"
                            else "ROUGE vs transpile judge: idiomatic similarity score"
                        }</span>
                    </div>
                </Field>
                <Field label="MODEL">
                    <div className="flex flex-col gap-2">
                        {len(avail) > 0 and <div className="flex flex-wrap gap-1">
                            {for m in avail {
                                <Chip
                                    key={str(m.id)}
                                    onClick={lambda e: MouseEvent { modelId = m.id; modelPath = ""; }}
                                    selected={modelId == m.id and not modelPath}
                                    className="px-2"
                                >
                                    {m.label}
                                </Chip>
                            }}
                        </div>}
                        <TextInput
                            value={modelPath}
                            onSet={lambda v: str { modelPath = v; if v { modelId = ""; } }}
                            placeholder="or model path (models/...)"
                            mono={True}
                        />
                    </div>
                </Field>
                <Field label="ADAPTER (optional)">
                    <TextInput value={adapter} onSet={lambda v: str { adapter = v; }} placeholder="e.g. model-experiments/01-sft-dpo/adapters/qwen-probe" mono={True} />
                </Field>
                <Field label="HOLDOUT">
                    <Segmented options={["function", "graph"]} value={holdout} onSet={lambda v: str { holdout = v; }} />
                </Field>
                <Field label="LIMIT">
                    <TextInput value={limit} onSet={lambda v: str { limit = v; }} placeholder="all" mono={True} />
                </Field>
                {kind == "idiom" and <Field label="SIM THRESHOLD">
                    <TextInput value={simThreshold} onSet={lambda v: str { simThreshold = v; }} placeholder="0.7" mono={True} />
                </Field>}
                <Button
                    variant="solid"
                    onClick={lambda e: MouseEvent { start(); }}
                    disabled={busy}
                    className="mt-1 w-full py-1.5"
                >
                    {"LAUNCHING…" if busy else "LAUNCH"}
                </Button>
                {error and <span className="stat-line text-foreground">{error}</span>}
            </div>
        </div>;
    }

    def _scoreTiles(run: any) -> JsxElement {
        sc: any = run.scores;
        if str(run.kind) == "probe" {
            return <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <StatTile label="TEST.PASS%" value={_g(sc, "test_pass_pct")} sub="" dim={False} />
                <StatTile label="RUNS%" value={_g(sc, "runs_pct")} sub="" dim={False} />
                <StatTile label="TOK/CORRECT" value={_g(sc, "tokens_to_correct")} sub="" dim={False} />
                <StatTile label="EVAL.TPS" value={_g(sc, "eval_tps")} sub="" dim={False} />
            </div>;
        }
        return <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <StatTile label="AVG.SIM" value={_g(sc, "avg_sim")} sub="" dim={False} />
            <StatTile label="IDIOMATIC" value={_idiomatic(sc)} sub="" dim={False} />
            <StatTile label="PY.SHAPED" value={_g(sc, "python_shaped")} sub="" dim={False} />
            <StatTile label="FEAT" value={_g(sc, "avg_feat")} sub="" dim={False} />
        </div>;
    }

    def _runView -> JsxElement {
        run: any = current;
        return <div className="relative rounded-md border border-border bg-card p-4 pt-5">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">ACTIVE RUN</span>
            {if not run {
                <span key="none" className="micro-label text-muted-foreground/70">NO ACTIVE EVAL</span>
                skip;
            }}
            {if run {
                <div key="run" className="flex flex-col gap-4">
                    <div className="flex items-center justify-between gap-3">
                        <div className="flex min-w-0 items-center gap-3">
                            <StatusGlyph status={str(run.status)} showLabel={True} />
                            <span className="truncate font-mono text-xs text-foreground/80">
                                #{str(run.id)} {str(run.kind)} · {_stripModels(str(run.model))} · {str(run.holdout)}
                            </span>
                        </div>
                        {str(run.status) == "running" and <Button
                            variant="ghost"
                            onClick={lambda e: MouseEvent { stopActive(); }}
                            className="shrink-0"
                        >
                            STOP
                        </Button>}
                    </div>
                    {run.scores and _scoreTiles({"run": run})}
                    <LogView text={str(run.log_tail)} maxH="16rem" />
                </div>
                skip;
            }}
        </div>;
    }

    def _history -> JsxElement {
        return <div className="relative rounded-md border border-border bg-card p-4 pt-5">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">HISTORY</span>
            {if len(history) == 0 {
                <span className="micro-label text-muted-foreground/70">no evals yet</span>
                skip;
            }}
            {if len(history) > 0 {
                <div className="overflow-x-auto">
                    <table className="w-full text-xs">
                        <thead>
                            <tr className="border-b border-border text-muted-foreground/70">
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">#</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">DATE</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">KIND</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">MODEL</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">HOLDOUT</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">SCORE</th>
                                <th className="micro-label pb-1.5 pr-3 text-left font-normal">ST</th>
                                <th className="micro-label pb-1.5 text-left font-normal" />
                            </tr>
                        </thead>
                        <tbody>
                            {for r in history {
                                <tr
                                    key={str(r.id)}
                                    onClick={lambda e: MouseEvent { openEval(str(r.id)); }}
                                    className="cursor-pointer border-b border-border/50 text-muted-foreground transition-colors hover:bg-popover hover:text-foreground"
                                >
                                    <td className="py-1.5 pr-3 font-mono text-muted-foreground">{str(r.id)}</td>
                                    <td className="whitespace-nowrap py-1.5 pr-3 font-mono">{str(r.started)[:16]}</td>
                                    <td className="py-1.5 pr-3">{str(r.kind)}</td>
                                    <td className="max-w-[160px] truncate py-1.5 pr-3 font-mono" title={str(r.model)}>{_stripModels(str(r.model))}</td>
                                    <td className="py-1.5 pr-3">{str(r.holdout)}</td>
                                    <td className="py-1.5 pr-3 font-mono">{_headline(r)}</td>
                                    <td className="py-1.5 pr-3"><StatusGlyph status={str(r.status)} showLabel={False} /></td>
                                    <td className="py-1.5">
                                        <Button
                                            variant="ghost"
                                            onClick={lambda e: MouseEvent { e.stopPropagation(); removeEval(str(r.id)); }}
                                            className="p-0"
                                        >
                                            DEL
                                        </Button>
                                    </td>
                                </tr>
                            }}
                        </tbody>
                    </table>
                </div>
                skip;
            }}
        </div>;
    }

    # All-optional params: called with a props dict (compiler quirk), which the
    # checker otherwise flags E1050 "missing required parameters".
    def _cell(done: any = None, mdl: any = None, h: str = "", bestProbe: any = None, bestIdiom: any = None) -> JsxElement {
        rec = _match(done, mdl, h);
        txt = "·";
        isBest = False;
        if rec is not None {
            n = _headNum(rec);
            if n >= 0.0 {
                if str(rec.kind) == "probe" {
                    txt = _headDisp(rec) + "%";
                    if h in bestProbe and float(str(bestProbe[h])) == n { isBest = True; }
                } else {
                    txt = "sim " + _headDisp(rec);
                    if h in bestIdiom and float(str(bestIdiom[h])) == n { isBest = True; }
                }
            }
        }
        cls = "py-1.5 pr-4 font-mono " + ("font-semibold text-foreground" if isBest else "text-muted-foreground");
        return <td key={h} className={cls}>{txt}</td>;
    }

    def _compare -> JsxElement {
        done: list = [];
        for r in history {
            if str(r.status) == "done" { done.append(r); }
        }
        if len(done) < 2 {
            return <div className="relative rounded-md border border-border bg-card p-4 pt-5">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">MODEL × HOLDOUT</span>
                <span className="micro-label text-muted-foreground/70">need ≥2 completed evals</span>
            </div>;
        }
        modelsU: list = [];
        for r in done {
            if r.model not in modelsU { modelsU.append(r.model); }
        }
        holdouts = ["function", "graph"];

        bestProbe: dict = {};
        bestIdiom: dict = {};
        for h in holdouts {
            bp = -1.0;
            haveProbe = False;
            for mdl in modelsU {
                rec = _match(done, mdl, h);
                if rec is not None and str(rec.kind) == "probe" {
                    n = _headNum(rec);
                    if n >= 0.0 and (not haveProbe or n > bp) { bp = n; haveProbe = True; }
                }
            }
            if haveProbe {
                bestProbe[h] = bp;
            } else {
                bi = -1.0;
                haveIdiom = False;
                for mdl in modelsU {
                    rec = _match(done, mdl, h);
                    if rec is not None and str(rec.kind) == "idiom" {
                        n = _headNum(rec);
                        if n >= 0.0 and (not haveIdiom or n < bi) { bi = n; haveIdiom = True; }
                    }
                }
                if haveIdiom { bestIdiom[h] = bi; }
            }
        }

        return <div className="relative rounded-md border border-border bg-card p-4 pt-5">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">MODEL × HOLDOUT</span>
            <div className="overflow-x-auto">
                <table className="w-full text-xs">
                    <thead>
                        <tr className="border-b border-border text-muted-foreground/70">
                            <th className="micro-label pb-1.5 pr-4 text-left font-normal">MODEL</th>
                            {for h in holdouts {
                                <th key={h} className="micro-label pb-1.5 pr-4 text-left font-normal">{h.upper()}</th>
                            }}
                        </tr>
                    </thead>
                    <tbody>
                        {for mdl in modelsU {
                            <tr key={str(mdl)} className="border-b border-border/50">
                                <td className="max-w-[160px] truncate py-1.5 pr-4 font-mono text-muted-foreground" title={str(mdl)}>{_stripModels(str(mdl))}</td>
                                {[_cell({"done": done, "mdl": mdl, "h": h, "bestProbe": bestProbe, "bestIdiom": bestIdiom}) for h in holdouts]}
                            </tr>
                        }}
                    </tbody>
                </table>
            </div>
        </div>;
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">RESULTS · EVAL RUNS</span>
        </div>
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            <div className="grid gap-4" style={{"gridTemplateColumns": "360px 1fr"}}>
                {_launch()}
                {_runView()}
            </div>
            <div className="grid grid-cols-2 gap-4">
                {_history()}
                {_compare()}
            </div>
            <Gallery prefix="model-experiments/01-sft-dpo" />
        </div>
    </div>;
}
