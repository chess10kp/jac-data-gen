"""RESULTS section (workspace 03 CPT) — side-by-side read of the CPT runs:
status/iters/final-loss tiles per run + both loss curves. Data straight from
get_all_cpt_status (same source TRAIN polls); fetched once per activation —
results don't change unless a run is training (watch that in TRAIN)."""

sv import from ...cpt { get_all_cpt_status }
import from ..shared.StatTile { StatTile }
import from ..shared.StatusGlyph { StatusGlyph }
import from ..shared.MonoChart { MonoChart }
import from ..shared.EmptyState { EmptyState }
import from ..shared.SectionHeader { SectionHeader }
import from ..shared.Gallery { Gallery }

glob RUNS: list[str] = ["cpt-v1", "cpt-v2"];

def _lastY(series: any) -> str {
    pts: list = list(series or []);
    if len(pts) == 0 { return "·"; }
    return str(pts[len(pts) - 1]["y"]);
}

def:pub CptResults(active: bool = False) -> JsxElement {
    has all: any = None,
        loadedOnce: bool = False;

    async can with [active] entry {
        if active {
            try {
                all = await get_all_cpt_status();
                loadedOnce = True;
            } except Exception { }
        }
    }

    def RunBlock(name: any = None) -> JsxElement {
        a: any = all;
        d: any = None;
        if a {
            try { d = a[str(name)]; } except Exception { d = None; }
        }
        if not d {
            return <div key={str(name)}><EmptyState label={"NO DATA · " + str(name)} /></div>;
        }
        return <div key={str(name)} className="flex flex-col gap-3">
            <div className="flex items-center gap-3">
                <span className="font-mono text-xs text-foreground">{str(name)}</span>
                <StatusGlyph status={str(d["status"])} showLabel={True} />
                {str(d["message"] or "") and <span className="stat-line">{str(d["message"])}</span>}
            </div>
            <div className="grid grid-cols-3 gap-3">
                <StatTile label="ITERS" value={str(d["last_iter"]) + "/" + str(d["total_iters"])} sub="steps" dim={False} />
                <StatTile label="TRAIN.LOSS" value={_lastY(d["train"])} sub="final" dim={False} />
                <StatTile label="VAL.LOSS" value={_lastY(d["val"])} sub="final" dim={False} />
            </div>
            <MonoChart title={"LOSS · " + str(name)} data={list(d["train"] or [])} secondary={list(d["val"] or [])} live={False} accent={"var(--chart-1)" if str(name) == "cpt-v1" else "var(--chart-2)"} expY={False} />
        </div>;
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <SectionHeader title={<span className="micro-label">RESULTS · CPT RUNS</span>} />
        <div className="flex flex-1 flex-col gap-6 overflow-y-auto p-4">
            {if not loadedOnce {
                <EmptyState key="loading" label="LOADING" pulse={True} />
                skip;
            }}
            {if loadedOnce {
                <div key="grid" className="grid grid-cols-1 gap-6 xl:grid-cols-2">
                    {for nm in RUNS {
                        <RunBlock key={nm} name={nm} />
                    }}
                </div>
                skip;
            }}
            <Gallery prefix="model-experiments/03-new" />
            <div className="stat-line text-muted-foreground/70">checkpoint verdicts + analysis live in PLAN and model-experiments/03-new/docs · curves are the same train.log TRAIN reads</div>
        </div>
    </div>;
}
