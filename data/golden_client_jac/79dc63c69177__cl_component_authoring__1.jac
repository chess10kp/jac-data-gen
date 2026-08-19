"""TRAIN section (workspace 03 CPT) — launch/monitor CPT LoRA runs.

Multi-run: polls get_all_cpt_status() every 2.5s while active and lets a Chip
row pick between cpt-v1 (plain single run, START/RESUME via start_cpt_training)
and cpt-v2 (the leg-based flow: one leg = one epoch via start_cpt_leg, which
persists optimizer state across legs and must run legs in order). Charts,
stat tiles and log all show the SELECTED run; the feed live/stalled/nofeed
tracker runs per-run so switching chips keeps liveness honest. Backed by
cpt.sv.jac's start_cpt_training/start_cpt_leg/stop_cpt_training/
get_all_cpt_status.
"""

import from react { useEffect }
sv import from ...cpt { start_cpt_training, start_cpt_leg, stop_cpt_training, get_all_cpt_status }
import from ..shared.StatusGlyph { StatusGlyph }
import from ..shared.StatTile { StatTile }
import from ..shared.LogView { LogView }
import from ..shared.MonoChart { MonoChart }
import from ..shared.Button { Button }
import from ..shared.Chip { Chip }

glob RUNS: list[str] = ["cpt-v1", "cpt-v2"];
glob CC: dict = {"loss": "var(--chart-2)", "lr": "var(--chart-1)", "tps": "var(--chart-5)"};

def _fix(v: any, n: int) -> str {
    return str(v.toFixed(n));
}

def:pub CptTrain(active: bool) -> JsxElement {
    has allStatus: any = None,
        selected: str = "cpt-v2",
        error: str = "",
        note: str = "",
        feeds: dict = {"cpt-v1": "nofeed", "cpt-v2": "nofeed"},
        stalls: dict = {"cpt-v1": 0, "cpt-v2": 0};

    async def _poll(tracker: dict) -> None {
        try {
            res = await get_all_cpt_status();
            allStatus = res;
            error = "";
            nf: dict = {};
            ns: dict = {};
            for nm in RUNS {
                s: any = res[nm];
                t: any = tracker[nm];
                if str(s["status"]) != "running" {
                    t["feed"] = "nofeed";
                    t["same"] = 0;
                    ns[nm] = 0;
                } else {
                    li = int(str(s["last_iter"]));
                    if li > int(str(t["iter"])) {
                        t["iter"] = li;
                        t["same"] = 0;
                        t["feed"] = "live";
                        ns[nm] = 0;
                    } else {
                        sm = int(str(t["same"])) + 1;
                        t["same"] = sm;
                        if sm >= 12 {
                            t["feed"] = "stalled";
                            ns[nm] = int(sm * 5 / 2);
                        } else {
                            ns[nm] = 0;
                        }
                    }
                }
                nf[nm] = str(t["feed"]);
            }
            feeds = nf;
            stalls = ns;
        } except Exception {
            error = "fetch error";
        }
    }

    useEffect(lambda {
        iv: any = None;
        if active {
            tracker: dict = {
                "cpt-v1": {"iter": -1, "same": 0, "feed": "nofeed"},
                "cpt-v2": {"iter": -1, "same": 0, "feed": "nofeed"}
            };
            cb = lambda { _poll(tracker); };
            cb();
            iv = setInterval(cb, 2500);
        }
        return lambda { if iv is not None { clearInterval(float(str(iv))); } };
    }, [active]);

    async def doStart() -> None {
        note = "";
        try {
            s = await start_cpt_training(name=selected);
            note = str(s["message"] or "");
            error = "";
            res = await get_all_cpt_status();
            allStatus = res;
        } except Exception as e {
            ex: any = e;
            error = str(ex.message or "start failed");
        }
    }
    async def doStartLeg(lg: int) -> None {
        note = "";
        try {
            s = await start_cpt_leg(name=selected, leg=lg);
            note = str(s["message"] or "");
            error = "";
            res = await get_all_cpt_status();
            allStatus = res;
        } except Exception as e {
            # backend raises ValueError on out-of-order legs — surface its text
            ex: any = e;
            error = str(ex.message or "start leg failed");
        }
    }
    async def doStop() -> None {
        try {
            cur: any = allStatus;
            rid = str(cur[selected]["run_id"] or "") if cur is not None and cur[selected] is not None else "";
            s = await stop_cpt_training(name=selected, run_id=rid);
            note = str(s["message"] or "");
            res = await get_all_cpt_status();
            allStatus = res;
        } except Exception as e {
            ex: any = e;
            error = str(ex.message or "stop failed");
        }
    }

    status: any = allStatus[selected] if allStatus is not None else None;
    feed = str(feeds[selected]);
    stalledFor = int(str(stalls[selected]));

    isRunning = status is not None and str(status["status"]) == "running";

    lastIter = int(str(status["last_iter"])) if status is not None else 0;
    totalIters = int(str(status["total_iters"])) if status is not None else 0;
    pct = (lastIter * 100.0) / totalIters if totalIters > 0 else 0.0;
    # leg/leg_ceiling are only nonzero for the CPT-v2 multi-leg flow
    # (start_cpt_leg in cpt.sv.jac); leg_ceiling == 0 means plain single run.
    leg = int(str(status["leg"])) if status is not None else 0;
    legCeiling = int(str(status["leg_ceiling"])) if status is not None else 0;
    isLeg = legCeiling > 0;
    isComplete = totalIters > 0 and lastIter >= totalIters;

    # Next-leg derivation: status only carries `leg` while a leg job record is
    # live, so when idle we recover completed legs from the cumulative iter
    # count: floor(last_iter / (total_iters / leg_ceiling)); next = that + 1.
    doneLegs = 0;
    nextLeg = 1;
    if legCeiling > 0 and totalIters > 0 {
        doneLegs = int((lastIter * legCeiling) / totalIters);
        nextLeg = doneLegs + 1;
    }
    curLeg = leg if (isRunning and leg > 0) else doneLegs;
    legDone = isLeg and nextLeg > legCeiling;

    train: list = list(status["train"]) if status is not None else [];
    val: list = list(status["val"]) if status is not None else [];
    lr: list = list(status["lr"]) if status is not None else [];
    tps: list = list(status["tps"]) if status is not None else [];
    lastTrain: any = train[len(train) - 1] if len(train) > 0 else None;
    lastVal: any = val[len(val) - 1] if len(val) > 0 else None;
    lastTps: any = tps[len(tps) - 1] if len(tps) > 0 else None;

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">TRAIN · CPT LoRA · {selected}</span>
            <StatusGlyph
                status={feed}
                showLabel={True}
                label={("STALLED " + str(stalledFor) + "s") if feed == "stalled" else ""}
            />
        </div>

        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            <div className="flex flex-wrap items-center gap-2">
                <span className="micro-label">RUN</span>
                {for nm in RUNS {
                    <Chip
                        key={nm}
                        onClick={lambda e: MouseEvent { selected = nm; note = ""; error = ""; }}
                        selected={selected == nm}
                        className="flex items-center gap-2 px-4 py-1.5 font-mono text-[10px] tracking-widest"
                    >
                        <StatusGlyph
                            status={str(allStatus[nm]["status"]) if allStatus is not None and allStatus[nm] is not None else "idle"}
                            showLabel={False}
                        />
                        <span key="nm">{nm}</span>
                    </Chip>
                }}
            </div>

            <div className="grid grid-cols-4 gap-3">
                <StatTile label="STATUS" value={(str(status["status"]).upper() if status is not None else "IDLE")} sub="" dim={False} />
                <StatTile label="ITER" value={f"{lastIter}/{totalIters}"} sub={_fix(pct, 1) + "%"} dim={False} />
                <StatTile label="TRAIN.LOSS" value={_fix(lastTrain["y"], 3) if lastTrain is not None else "·"} sub={("val " + _fix(lastVal["y"], 3)) if lastVal is not None else ""} dim={False} />
                <StatTile label="TOK/S" value={_fix(lastTps["y"], 0) if lastTps is not None else "·"} sub="" dim={False} />
            </div>

            <div className="relative rounded-md border border-border bg-card p-3 pt-4">
                <span className="micro-label absolute -top-2 left-3 bg-background px-2">CONTROLS · {selected}</span>
                <div className="flex items-center gap-3">
                    <StatusGlyph status={str(status["status"]) if status is not None else "idle"} showLabel={True} />
                    <div className="h-1 flex-1 rounded-full bg-accent">
                        <div className="h-1 rounded-full transition-all" style={{"width": _fix(pct, 1) + "%", "background": "var(--ws-accent)"}}></div>
                    </div>
                </div>
                {isLeg and <p className="stat-line mt-2 text-foreground">LEG {str(curLeg)}/{str(legCeiling)}{(" · next: leg " + str(nextLeg)) if not isRunning and not legDone else ""}</p>}
                {note and <p className="stat-line mt-2 text-foreground">{note}</p>}
                {status is not None and status["message"] and <p className="stat-line mt-2 text-muted-foreground">{str(status["message"])}</p>}
                {not isLeg and isComplete and <p className="stat-line mt-1 text-muted-foreground">already complete ({str(lastIter)}/{str(totalIters)}) — nothing left to run</p>}
                {status is not None and str(status["started"]) and <p className="stat-line mt-1 text-muted-foreground/70">STARTED {str(status["started"])}{(" · PID " + str(status["pid"])) if int(str(status["pid"])) > 0 else ""}</p>}
                <div className="mt-3 flex gap-2">
                    {not isLeg and <Button variant="solid" onClick={lambda e: MouseEvent { doStart(); }} disabled={isRunning or isComplete}>▶ START / RESUME</Button>}
                    {isLeg and <Button variant="solid" onClick={lambda e: MouseEvent { doStartLeg(nextLeg); }} disabled={isRunning or legDone}>{(("▶ START LEG " + str(nextLeg)) if not legDone else "✓ ALL LEGS DONE")}</Button>}
                    <Button variant="outline" onClick={lambda e: MouseEvent { doStop(); }} disabled={not isRunning}>■ STOP</Button>
                </div>
                {error and <p className="stat-line mt-1 text-warning">{error}</p>}
                {not isLeg and <p className="stat-line mt-2 text-muted-foreground/70">single mlx_lm.lora run · resumes from the last checkpoint if stopped and restarted</p>}
                {isLeg and <p className="stat-line mt-2 text-muted-foreground/70">one leg = one epoch · optimizer state persists across legs · legs must run in order</p>}
            </div>

            <div className="grid grid-cols-2 gap-4">
                <MonoChart title="LOSS · train + val" data={train} secondary={val} live={feed == "live"} accent={str(CC["loss"])} expY={False} />
                <MonoChart title="LEARNING.RATE" data={lr} secondary={[]} live={False} accent={str(CC["lr"])} expY={True} />
                <MonoChart title="TOKENS/SEC" data={tps} secondary={[]} live={feed == "live"} accent={str(CC["tps"])} expY={False} />
            </div>

            <LogView text={str(status["log_tail"]) if status is not None and status["log_tail"] else ""} maxH="16rem" />
        </div>
    </div>;
}
