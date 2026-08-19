"""TRAIN section — launch / monitor / history. Ports ui/components/sections/train/*.

LAUNCH: config form + start/stop + live RUN.STATUS panel.
MONITOR: running-session picker + LIVE/STALLED/NO FEED chip + RunDetail (polled).
HISTORY: runs (pick model+stage → RunDetail) | compare (table + overlay charts).

Backed by train.sv.jac (start/stop/status/sessions) + runs.sv.jac (get_run/compare).
Polling uses manual `useEffect` + setInterval so the interval is re-established when
its deps change (avoids stale-closure reads); cross-tick stall tracking lives in an
effect-local dict (mutated by reference, never via React state).
"""

import from react { useEffect }
sv import from ...train { start_training, stop_training, get_status, list_sessions }
sv import from ...runs { get_run, compare_runs }
import from ..shared.SubTabs { SubTabs }
import from ..shared.Field { Field, TextInput, Segmented }
import from ..shared.StatusGlyph { StatusGlyph }
import from ..shared.LogView { LogView }
import from ..shared.StatTile { StatTile }
import from ..shared.MonoChart { MonoChart }
import from ..shared.MultiLineChart { MultiLineChart }
import from ..shared.Button { Button }
import from ..shared.Chip { Chip }

glob TABS: list[str] = ["LAUNCH", "MONITOR", "HISTORY"];
glob SFT_OPT_KEYS: list[str] = ["EVAL_EVERY", "SUBSET", "DRY_ITERS", "SKIP_DRY"];
glob DPO_OPT_KEYS: list[str] = ["DPO_ITERS", "DPO_LR", "DPO_BETA", "SUBSET"];
glob CC: dict = {"loss": "var(--chart-2)", "lr": "var(--chart-1)", "tps": "var(--chart-5)", "acc": "var(--chart-3)"};
glob COLORS: list[str] = [
    "var(--chart-1)", "var(--chart-2)", "var(--chart-3)",
    "var(--chart-4)", "var(--chart-5)", "var(--chart-6)"
];
glob MODE_DESC: dict = {
    "sft": "supervised finetune · teaches the model to write Jac",
    "dpo": "preference tuning · pushes outputs toward idiomatic Jac"
};

# ---------------------------------------------------------------------------
# numeric/format helpers (no `any` locals in the arithmetic)
# ---------------------------------------------------------------------------

def _fix(v: any, n: int) -> str {
    return str(v.toFixed(n));
}

def _idiomPctNum(s: any) -> any {
    hsv = bool(s["has"]);
    runs = int(str(s["runs"]));
    idio = int(str(s["idiomatic"]));
    if hsv and runs > 0 { return round(idio * 100 / runs); }
    return None;
}

def _idiomPct(s: any) -> str {
    v = _idiomPctNum(s);
    if v is None { return "·"; }
    return str(v) + "%";
}

def _idiomSub(s: any, fallback: str) -> str {
    if not bool(s["has"]) { return fallback; }
    return f"{s['idiomatic']}/{s['runs']} idiomatic · sim {s['avg_sim']} · {s['total']} tasks";
}

# ---------------------------------------------------------------------------
# RunDetail — 4 headline tiles + 2 holdout tiles + 4 charts + log tail
# ---------------------------------------------------------------------------

def:pub RunDetail(metrics: any, live: bool) -> JsxElement {
    train: list = list(metrics["train"]);
    val: list = list(metrics["val"]);
    lr: list = list(metrics["lr"]);
    tps: list = list(metrics["tps"]);
    curve: list = list(metrics["curve"]);
    lastTrain: any = train[len(train) - 1] if len(train) > 0 else None;
    lastVal: any = val[len(val) - 1] if len(val) > 0 else None;
    lastTps: any = tps[len(tps) - 1] if len(tps) > 0 else None;
    lastAcc: any = curve[len(curve) - 1] if len(curve) > 0 else None;
    fi: any = metrics["func_idiom"];
    gi: any = metrics["graph_idiom"];

    return <>
        <div className="grid grid-cols-4 gap-3">
            <StatTile label="ACCURACY · TEST-PASS%" value={(str(lastAcc["y"]) + "%") if lastAcc is not None else "·"} sub="cross-compiled holdout" dim={False} />
            <StatTile label="LAST.ITER" value={str(metrics["last_iter"])} sub="" dim={False} />
            <StatTile label="FINAL.LOSS" value={_fix(lastTrain["y"], 3) if lastTrain is not None else "·"} sub={("val " + _fix(lastVal["y"], 3)) if lastVal is not None else ""} dim={False} />
            <StatTile label="TOK/S" value={_fix(lastTps["y"], 0) if lastTps is not None else "·"} sub="" dim={False} />
        </div>

        <div className="grid grid-cols-2 gap-3">
            <StatTile label="FUNCTION HOLDOUT · IDIOMATIC" value={_idiomPct(fi)} sub={_idiomSub(fi, "no function-holdout eval")} dim={False} />
            <StatTile label="GRAPH HOLDOUT · IDIOMATIC" value={_idiomPct(gi)} sub={_idiomSub(gi, "no graph-holdout eval")} dim={False} />
        </div>

        <div className="grid grid-cols-2 gap-4">
            <MonoChart title="LOSS · train + val" data={train} secondary={val} live={live} accent={str(CC["loss"])} expY={False} />
            <MonoChart title="LEARNING.RATE" data={lr} secondary={[]} live={False} accent={str(CC["lr"])} expY={True} />
            <MonoChart title="TOKENS/SEC" data={tps} secondary={[]} live={False} accent={str(CC["tps"])} expY={False} />
            <MonoChart title="ACCURACY · TEST-PASS%" data={curve} secondary={[]} live={live} accent={str(CC["acc"])} expY={False} />
        </div>

        <LogView text={str(metrics["log_tail"])} maxH="12rem" />
    </>;
}

# ---------------------------------------------------------------------------
# compare table helpers
# ---------------------------------------------------------------------------

def _hMetrics(h: any) -> dict {
    return {
        "fp": float(str(h["final_pass"])),
        "ll": float(str(h["last_loss"])),
        "li": int(str(h["last_iter"])),
        "fpct": _idiomPctNum(h["func_idiom"]),
        "gpct": _idiomPctNum(h["graph_idiom"]),
        "fhas": bool(h["func_idiom"]["has"]),
        "ghas": bool(h["graph_idiom"]["has"]),
        "fsim": str(h["func_idiom"]["avg_sim"]),
        "gsim": str(h["graph_idiom"]["avg_sim"])
    };
}

# All-optional params: called with a props dict (compiler quirk), which the
# checker otherwise flags E1050 "missing required parameters".
def _cmpRow(label: any = "", cells: list = [], nums: list = [], best: str = "max") -> JsxElement {
    valid: list = [n for n in nums if n is not None];
    leader: any = None;
    if len(valid) > 1 {
        leader = max(valid) if best == "max" else min(valid);
    }
    return <tr key={label} className="border-t border-border/60">
        <td className="py-1.5 pr-4 text-muted-foreground">{label}</td>
        {for (i, c) in enumerate(cells) {
            <td key={str(i)} className={"py-1.5 px-4 text-right " + (
                "text-foreground font-semibold" if (leader is not None and nums[i] is not None and nums[i] == leader) else "text-muted-foreground"
            )}>{c}</td>
        }}
    </tr>;
}

# `headline: any` — receives a props dict at the call site (same quirk as _cmpRow).
def _compareTable(headline: any = None) -> JsxElement {
    hm: list = [_hMetrics(h) for h in headline];
    names: list = [str(h["name"]) for h in headline];
    accCells: list = [f"{m['fp']}%" for m in hm];
    accNums: list = [m["fp"] for m in hm];
    lossCells: list = [str(m["ll"]) for m in hm];
    lossNums: list = [m["ll"] for m in hm];
    iterCells: list = [str(m["li"]) for m in hm];
    iterNums: list = [m["li"] for m in hm];
    fpctCells: list = ["·" if m["fpct"] is None else f"{m['fpct']}%" for m in hm];
    fpctNums: list = [m["fpct"] for m in hm];
    fsimCells: list = [m["fsim"] if m["fhas"] else "·" for m in hm];
    gpctCells: list = ["·" if m["gpct"] is None else f"{m['gpct']}%" for m in hm];
    gpctNums: list = [m["gpct"] for m in hm];
    gsimCells: list = [m["gsim"] if m["ghas"] else "·" for m in hm];
    nullNums: list = [None for m in hm];

    return <div className="relative rounded-md border border-border bg-card p-3 pt-5 overflow-x-auto">
        <span className="micro-label absolute -top-2 left-3 bg-background px-2">COMPARISON</span>
        <table className="w-full border-collapse font-mono text-xs">
            <thead>
                <tr>
                    <th className="micro-label py-2 pr-4 text-left font-normal">METRIC</th>
                    {for (i, nm) in enumerate(names) {
                        <th key={nm} className="py-2 px-4 text-right font-normal" style={{"color": COLORS[i % len(COLORS)]}}>{str(nm).upper()}</th>
                    }}
                </tr>
            </thead>
            <tbody>
                {_cmpRow({"label": "ACCURACY · TEST-PASS%", "cells": accCells, "nums": accNums, "best": "max"})}
                {_cmpRow({"label": "FINAL LOSS", "cells": lossCells, "nums": lossNums, "best": "min"})}
                {_cmpRow({"label": "ITERATIONS", "cells": iterCells, "nums": iterNums, "best": "max"})}
                {_cmpRow({"label": "FUNCTION HOLDOUT · IDIOMATIC%", "cells": fpctCells, "nums": fpctNums, "best": "max"})}
                {_cmpRow({"label": "FUNCTION HOLDOUT · SIM", "cells": fsimCells, "nums": nullNums, "best": "min"})}
                {_cmpRow({"label": "GRAPH HOLDOUT · IDIOMATIC%", "cells": gpctCells, "nums": gpctNums, "best": "max"})}
                {_cmpRow({"label": "GRAPH HOLDOUT · SIM", "cells": gsimCells, "nums": nullNums, "best": "min"})}
            </tbody>
        </table>
    </div>;
}

# ---------------------------------------------------------------------------
# TRAIN
# ---------------------------------------------------------------------------

def:pub Train(active: bool) -> JsxElement {
    has tab: str = "launch";
    has sessions: list = [];
    has formModelId: str = "Qwen/Qwen3-Coder-30B-A3B-Instruct";
    has formName: str = "qwen";
    has formMode: str = "sft";
    has opts: dict = {
        "EVAL_EVERY": "60", "SUBSET": "50", "DRY_ITERS": "30", "SKIP_DRY": "0",
        "DPO_ITERS": "200", "DPO_LR": "1e-6", "DPO_BETA": "0.1"
    };
    has job: any = None;
    has launchedRun: dict = {};
    has error: str = "";
    has selName: str = "";
    has selMode: str = "";
    has metrics: any = None;
    has feed: str = "nofeed";
    has stalledFor: int = 0;
    has compare: any = None;
    has compareMode: str = "sft";
    has historyView: str = "runs";
    has histName: str = "";
    has histMode: str = "sft";
    has historyMetrics: any = None;

    # ---- async fetchers (set state only; logic params passed explicitly) ----
    async def _pollSessions() -> None {
        try {
            r = await list_sessions();
            sessions = list(r["sessions"]);
        } except Exception {}
    }
    async def _pollStatus(nm: str, md: str) -> None {
        try {
            j = await get_status(name=nm, mode=md);
            job = j;
            error = "";
        } except Exception {
            error = "fetch error";
        }
    }
    async def _pollMetrics(nm: str, md: str, tracker: dict) -> None {
        try {
            m = await get_run(name=nm, mode=md);
            metrics = m;
            if not bool(m["found"]) or not bool(m["running"]) {
                feed = "nofeed";
                return;
            }
            li = int(str(m["last_iter"]));
            if li > int(str(tracker["iter"])) {
                tracker["iter"] = li;
                tracker["same"] = 0;
                feed = "live";
                stalledFor = 0;
            } else {
                sm = int(str(tracker["same"])) + 1;
                tracker["same"] = sm;
                if sm >= 12 {
                    feed = "stalled";
                    stalledFor = int(sm * 5 / 2);
                }
            }
        } except Exception {}
    }
    async def _fetchCompare(cm: str) -> None {
        try {
            r = await compare_runs(mode=cm);
            compare = r;
        } except Exception {}
    }
    async def _fetchHistMetrics(nm: str, md: str) -> None {
        try {
            m = await get_run(name=nm, mode=md);
            historyMetrics = m;
        } except Exception {}
    }

    # ---- polling effects ----
    useEffect(lambda {
        iv: any = None;
        if active {
            _pollSessions();
            iv = setInterval(lambda { _pollSessions(); }, 5000);
        }
        return lambda { if iv is not None { clearInterval(float(str(iv))); } };
    }, [active]);

    useEffect(lambda {
        running: list = [s for s in sessions if str(s["status"]) == "running"];
        if selName != "" {
            still: list = [s for s in running if str(s["name"]) == selName and str(s["mode"]) == selMode];
            if len(still) == 0 { selName = ""; selMode = ""; }
        }
        if selName == "" and len(running) > 0 {
            selName = str(running[0]["name"]);
            selMode = str(running[0]["mode"]);
        }
    }, [sessions]);

    # Poll the LAUNCHED run when a launch handle exists (editing the form must
    # not repoint the status panel); fall back to form fields pre-launch.
    useEffect(lambda {
        iv: any = None;
        pinned: bool = "name" in launchedRun;
        nm: str = str(launchedRun["name"]) if pinned else formName;
        md: str = str(launchedRun["mode"]) if pinned else formMode;
        if active and tab == "launch" and nm != "" {
            _pollStatus(nm, md);
            iv = setInterval(lambda { _pollStatus(nm, md); }, 2500);
        }
        return lambda { if iv is not None { clearInterval(float(str(iv))); } };
    }, [active, tab, formName, formMode, launchedRun]);

    useEffect(lambda {
        iv: any = None;
        if active and tab == "monitor" and selName != "" {
            nm = selName;
            md = selMode;
            tracker: dict = {"iter": -1, "same": 0};
            cb = lambda { _pollMetrics(nm, md, tracker); };
            cb();
            iv = setInterval(cb, 2500);
        }
        return lambda { if iv is not None { clearInterval(float(str(iv))); } };
    }, [active, tab, selName, selMode]);

    useEffect(lambda {
        if active and tab == "history" { _fetchCompare(compareMode); }
    }, [active, tab, compareMode]);

    useEffect(lambda {
        if active and tab == "history" and historyView == "runs" and histName != "" {
            _fetchHistMetrics(histName, histMode);
        }
    }, [active, tab, historyView, histName, histMode]);

    useEffect(lambda {
        if active and tab == "history" and historyView == "runs" and histName == "" {
            cands: list = [s for s in sessions if str(s["mode"]) == compareMode and str(s["status"]) != "running"];
            if len(cands) > 0 {
                histName = str(cands[0]["name"]);
                histMode = str(cands[0]["mode"]);
            }
        }
    }, [active, tab, historyView, sessions, compareMode]);

    # ---- actions ----
    def onTab(t: str) -> None { tab = t.lower(); }
    def updateForm(key: str, value: str) -> None {
        if key == "modelId" { formModelId = value; }
        elif key == "name" { formName = value; }
        elif key == "mode" { formMode = value; }
    }
    def updateOpt(key: str, value: str) -> None {
        opts = {**opts, key: value};
    }
    def pickSession(nm: str, md: str) -> None {
        selName = nm; selMode = md; feed = "nofeed"; stalledFor = 0;
    }
    def pickHistory(nm: str, md: str) -> None {
        histName = nm; histMode = md; historyMetrics = None;
    }
    async def doStart() -> None {
        keys = SFT_OPT_KEYS if formMode == "sft" else DPO_OPT_KEYS;
        filtered: dict = {};
        for k in keys {
            if k in opts { filtered[k] = str(opts[k]); }
        }
        mid = formModelId if formMode == "sft" else "";
        nm = formName;
        md = formMode;
        try {
            j = await start_training(name=nm, mode=md, model_id=mid, opts=filtered);
            job = j;
            error = "";
            rid: str = str(j["run_id"]) if "run_id" in j else "";
            if rid != "" {
                # launch handle — status panel + stop now target THIS run,
                # regardless of later form edits.
                launchedRun = {"name": nm, "mode": md, "run_id": rid};
            }
        } except Exception {
            error = "start failed";
        }
    }
    async def doStop() -> None {
        try {
            if "run_id" in launchedRun {
                j = await stop_training(
                    name=str(launchedRun["name"]),
                    mode=str(launchedRun["mode"]),
                    run_id=str(launchedRun["run_id"])
                );
                job = j;
            } else {
                j = await stop_training(name=formName, mode=formMode);
                job = j;
            }
        } except Exception {
            error = "stop failed";
        }
    }
    # ---- LAUNCH tab ----
    def _launch() -> JsxElement {
        isRunning = job is not None and str(job["status"]) == "running";
        optKeys = SFT_OPT_KEYS if formMode == "sft" else DPO_OPT_KEYS;
        pinnedLine: str = (
            f"showing run {launchedRun['run_id']} · {launchedRun['name']}/{launchedRun['mode']}"
            if "run_id" in launchedRun else ""
        );
        # backend messages ("busy: <holder> is running", "run X superseded; not
        # stopped") arrive on the status/stop dict — must reach the UI.
        jobMsg: str = str(job["message"] or "") if job is not None else "";
        return <div className="flex items-start gap-4 p-4 pt-5">
            <div className="relative flex min-w-0 flex-1 flex-col gap-3 rounded-md border border-border bg-card p-4 pt-5">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">LAUNCH CONFIG</span>

                {formMode == "sft" and <Field label="BASE MODEL (HF ID)">
                    <TextInput value={formModelId} onSet={lambda v: str { updateForm("modelId", v); }} placeholder="org/model" mono={True} />
                </Field>}

                <Field label="SHORT NAME">
                    <TextInput value={formName} onSet={lambda v: str { updateForm("name", v); }} placeholder="qwen" mono={True} />
                </Field>

                <Field label="MODE">
                    <Segmented options={["sft", "dpo"]} value={formMode} onSet={lambda v: str { updateForm("mode", v); }} />
                </Field>

                {for key in optKeys {
                    <Field key={key} label={key}>
                        <TextInput value={str(opts[key]) if key in opts else ""} onSet={lambda v: str { updateOpt(key, v); }} placeholder={key} mono={True} />
                    </Field>
                }}

                <p className="stat-line mt-1 text-muted-foreground">heavy workload · one training at a time, runs detached</p>

                <div className="mt-2 flex gap-2">
                    <Button variant="solid" onClick={lambda e: MouseEvent { doStart(); }} disabled={isRunning}>▶ START {formMode.upper()}</Button>
                    <Button variant="outline" onClick={lambda e: MouseEvent { doStop(); }} disabled={not isRunning}>■ STOP</Button>
                </div>

                {error and <p className="stat-line mt-1 text-muted-foreground">{error}</p>}
            </div>

            <div className="relative flex min-w-0 flex-1 flex-col gap-3 rounded-md border border-border bg-card p-4 pt-5">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">RUN STATUS</span>

                {pinnedLine != "" and <p key="pinned-run" className="stat-line text-muted-foreground/70">{pinnedLine}</p>}

                <div className="flex flex-wrap items-center gap-3">
                    <StatusGlyph status={str(job["status"]) if job is not None else "idle"} showLabel={True} />
                </div>

                {jobMsg != "" and <p key="job-msg" className="stat-line text-warning">{jobMsg}</p>}

                {job is not None and <div className="flex flex-col gap-1">
                    {int(str(job["pid"])) > 0 and <span className="font-mono text-[11px] text-muted-foreground">PID {str(job["pid"])}</span>}
                    {str(job["started"]) and <span className="font-mono text-[11px] text-muted-foreground">STARTED {str(job["started"])}</span>}
                    {int(str(job["last_iter"])) > 0 and <span className="font-mono text-[11px] text-muted-foreground">LAST ITER {str(job["last_iter"])}</span>}
                </div>}

                <LogView text={str(job["log_tail"]) if job is not None else ""} maxH="24rem" />
            </div>
        </div>;
    }

    # ---- MONITOR tab ----
    def _monitor() -> JsxElement {
        running: list = [s for s in sessions if str(s["status"]) == "running"];
        if len(running) == 0 {
            return <div className="flex h-full flex-1 flex-col items-center justify-center gap-1 p-4">
                <span className="micro-label">NO LIVE RUNS</span>
                <span className="stat-line text-muted-foreground/70">launch from the LAUNCH tab · finished runs live in HISTORY</span>
            </div>;
        }
        found = metrics is not None and bool(metrics["found"]);
        return <div className="flex h-full min-h-0 flex-col gap-4 overflow-y-auto p-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="flex flex-wrap items-center gap-1">
                    {for s in running {
                        <Chip
                            key={str(s["name"]) + "|" + str(s["mode"])}
                            onClick={lambda e: MouseEvent { pickSession(str(s["name"]), str(s["mode"])); }}
                            selected={selName == str(s["name"]) and selMode == str(s["mode"])}
                            className="font-mono text-[10px] tracking-widest"
                        >
                            {str(s["label"]) if "label" in s else (str(s["name"]) + "·" + str(s["mode"]))}
                        </Chip>
                    }}
                </div>
                <StatusGlyph
                    status={feed}
                    showLabel={True}
                    label={f"STALLED {stalledFor}s" if feed == "stalled" else ""}
                />
            </div>

            {not found and <div className="flex flex-1 items-center justify-center"><span className="micro-label">NO RUN DATA</span></div>}
            {found and <RunDetail metrics={metrics} live={feed == "live"} />}
        </div>;
    }

    # ---- HISTORY tab ----
    # `pool: any` — receives the all-optional `pastSessions` props param (see _historyRuns).
    def _hasRun(pool: any, nm: str, md: str) -> bool {
        for s in pool {
            if str(s["name"]) == nm and str(s["mode"]) == md { return True; }
        }
        return False;
    }

    # `pastSessions: any` — receives a props dict at the call site (same quirk as _cmpRow).
    def _historyRuns(pastSessions: any = None) -> JsxElement {
        pool: list = list(pastSessions);
        if len(pool) == 0 {
            return <div className="flex flex-1 items-center justify-center"><span className="micro-label">NO FINISHED RUNS</span></div>;
        }
        mdls: list[str] = [];
        for s in pool {
            nm = str(s["name"]);
            if nm not in mdls { mdls.append(nm); }
        }
        selModel = histName;
        selModeH = histMode if histMode != "" else "sft";
        return <>
            <div className="flex flex-wrap items-end gap-x-8 gap-y-3">
                <div className="flex flex-col gap-1.5">
                    <span className="micro-label">MODEL</span>
                    <div className="flex gap-2">
                        {for name in mdls {
                            <Chip
                                key={name}
                                onClick={lambda e: MouseEvent { pickHistory(name, selModeH); }}
                                selected={selModel == name}
                                className="px-4 py-1.5 font-mono"
                            >
                                {name}
                            </Chip>
                        }}
                    </div>
                </div>

                <div className="flex flex-col gap-1.5">
                    <span className="micro-label">STAGE</span>
                    <div className="flex gap-2">
                        {for mode in ["sft", "dpo"] {
                            <button
                                key={mode}
                                disabled={not (_hasRun(pool, selModel, mode) if selModel != "" else True)}
                                onClick={lambda e: MouseEvent { pickHistory(selModel if selModel != "" else mdls[0], mode); }}
                                className={"rounded-md border px-4 py-1.5 font-mono text-xs uppercase tracking-widest transition-colors disabled:opacity-30 " + (
                                    ("border-chart-4/50 bg-accent text-chart-4" if mode == "dpo" else "border-chart-1/50 bg-accent text-chart-1") if selModeH == mode
                                    else "border-border text-muted-foreground hover:border-ring hover:text-foreground"
                                )}
                            >
                                {mode}
                            </button>
                        }}
                    </div>
                </div>

                <span className="stat-line pb-1.5 text-muted-foreground/70">{str(MODE_DESC[selModeH]) if selModeH in MODE_DESC else ""}</span>
            </div>

            {histName == "" and <div className="flex flex-1 items-center justify-center"><span className="micro-label">SELECT A MODEL ABOVE</span></div>}
            {histName != "" and not (historyMetrics is not None and bool(historyMetrics["found"])) and <div className="flex flex-1 items-center justify-center"><span className="micro-label">NO RUN DATA</span></div>}
            {histName != "" and historyMetrics is not None and bool(historyMetrics["found"]) and <RunDetail metrics={historyMetrics} live={False} />}
        </>;
    }

    def _historyCompare() -> JsxElement {
        hasData = compare is not None and len(list(compare["names"])) > 0;
        return <>
            <div className="flex items-center gap-3">
                <Segmented options={["sft", "dpo"]} value={compareMode} onSet={lambda v: str { compareMode = v; }} />
            </div>
            {not hasData and <div className="flex flex-1 items-center justify-center"><span className="micro-label">NO PAST RUNS</span></div>}
            {hasData and <>
                {_compareTable({"headline": list(compare["headline"])})}
                <div className="grid grid-cols-1 gap-4">
                    <MultiLineChart title="ACCURACY · TEST-PASS%" rows={list(compare["curve"])} names={list(compare["names"])} />
                    <MultiLineChart title="LOSS.TRAIN" rows={list(compare["train"])} names={list(compare["names"])} />
                    <MultiLineChart title="LOSS.VAL" rows={list(compare["val"])} names={list(compare["names"])} />
                </div>
            </>}
        </>;
    }

    def _history() -> JsxElement {
        pastSessions: list = [s for s in sessions if str(s["status"]) != "running"];
        return <div className="flex h-full min-h-0 flex-col gap-4 overflow-y-auto p-4">
            <div className="flex flex-wrap items-center gap-3">
                <Segmented options={["runs", "compare"]} value={historyView} onSet={lambda v: str { historyView = v; }} />
                <span className="stat-line text-muted-foreground/70">{"inspect one finished run in detail" if historyView == "runs" else "overlay every run of one stage"}</span>
            </div>
            {historyView == "runs" and _historyRuns({"pastSessions": pastSessions})}
            {historyView == "compare" and _historyCompare()}
        </div>;
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <SubTabs tabs={TABS} active={tab.upper()} onTab={onTab} />
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto">
            {tab == "launch" and _launch()}
            {tab == "monitor" and _monitor()}
            {tab == "history" and _history()}
        </div>
    </div>;
}
