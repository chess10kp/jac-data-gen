"""DATA section (workspace 01 SFT/DPO) — pipeline rail + add-examples (left) |
dataset browser (right).

Ports ui/components/sections/data/{data-section,pipeline-rail,add-examples,
dataset-browser,row-detail,stats-tiles}. The 13 build stages run as detached jobs
(builders.sv.jac); the browser is read-only over the preview-allowed files
(data.sv.jac); appends go through add_examples. Rows render via the shared RowBrowser.
The RL dataset browser lives in the 02 workspace's RlData section now.

# studio: the tsx polls builders only while a stage is running (usePoll). Reproducing
# that gate needs a fresh closure over state; instead we poll unconditionally every
# 3s while mounted — a touch more network, but correct and far simpler.
"""

sv import from ...data { dataset_stats, dataset_files, dataset_rows, add_examples, FileRefView, DataRowView }
sv import from ...builders { list_builders, run_builder, BuilderView }
import from ..shared.StatTile { StatTile }
import from ..shared.StatusGlyph { StatusGlyph }
import from ..shared.LogView { LogView }
import from ..shared.Field { Segmented }
import from ..shared.RowBrowser { RowBrowser }
import from ..shared.Button { Button }
import from ...hooks.useRowPager { useRowPager }

glob GROUPS: list[dict] = [
    {"label": "SEED", "stages": ["seed_conversion"]},
    {"label": "IDIOM BATCHES", "stages": ["idiomatic_batch", "idiomatic_batch2", "idiomatic_batch3"]},
    {"label": "SCALE", "stages": ["scale_conversion"]},
    {"label": "DPO", "stages": ["dpo_conversion"]},
    {"label": "MANIFEST+SPLITS", "stages": ["build_manifest", "build_splits", "build_dpo_splits"]},
    {"label": "HOLDOUTS", "stages": ["holdout", "graph_holdout"]},
    {"label": "AUDIT", "stages": ["dataset_stats", "verify_dataset"]}
];

def:pub Data(active: bool = False) -> JsxElement {
    has stats: any = None,
        builders: list = [],
        selectedStage: str = "",
        addTarget: str = "sft",
        addText: str = "",
        addResult: any = None,
        addBusy: bool = False,
        doneCount: int = 0,
        runningStage: str = "",
        pollId: any = None;

    async def _files -> any {
        return await dataset_files();
    }

    async def _rows(p: str, off: int) -> any {
        return await dataset_rows(p, off, 25);
    }

    # files/path/rows/offset/total/expanded + pager actions; loads the file
    # list and opens the first file on mount.
    pager = useRowPager(_files, _rows);

    async def loadBuilders() -> None {
        bs = await list_builders();
        builders = bs;
        dc = 0;
        rs = "";
        for b in bs {
            st = str(b.status);
            if st == "done" or st == "finished" {
                dc += 1;
            }
            if st == "running" {
                rs = str(b.stage);
            }
        }
        doneCount = dc;
        runningStage = rs;
    }

    def selectStage(s: str) -> None {
        selectedStage = s;
    }

    async def runStage(s: str) -> None {
        selectedStage = s;
        await run_builder(stage=s);
        await loadBuilders();
    }

    async def submitExamples() -> None {
        addBusy = True;
        addResult = None;
        r = await add_examples(target=addTarget, jsonl=addText);
        addResult = r;
        addBusy = False;
        if int(r["added"]) > 0 {
            stats = await dataset_stats();
            await pager["refreshFiles"]();
        }
    }

    # Poll the builder pipeline only while this section is visible — 11 sections
    # stay mounted, and an always-on 3s interval per hidden section is the poll
    # storm the backend used to eat.
    async can with [active] entry {
        if pollId is not None { clearInterval(float(str(pollId))); pollId = None; }
        if active {
            stats = await dataset_stats();
            await loadBuilders();
            pollId = setInterval(lambda -> None { loadBuilders(); }, 3000);
        }
    }

    can with exit {
        if pollId is not None {
            clearInterval(float(str(pollId)));
        }
    }

    def _statusOf(stage: str) -> str {
        for b in builders {
            if str(b.stage) == stage {
                return str(b.status);
            }
        }
        return "idle";
    }

    def _logOf(stage: str) -> str {
        for b in builders {
            if str(b.stage) == stage {
                return str(b.log_tail);
            }
        }
        return "";
    }

    def _tiles() -> JsxElement {
        if not stats {
            return <span className="micro-label">loading…</span>;
        }
        sp: any = stats["splits"];
        return <div className="grid grid-cols-3 gap-3 lg:grid-cols-6">
            <StatTile label="SFT.TOTAL" value={str(stats["sft_total"])} sub="examples" dim={False} />
            <StatTile label="DPO.PAIRS" value={str(stats["dpo_pairs"])} sub="pairs" dim={False} />
            <StatTile label="MLX.SFT" value={str(sp["mlx_train"]) + "/" + str(sp["mlx_valid"])} sub="train/valid" dim={False} />
            <StatTile label="MLX.DPO" value={str(sp["dpo_train"]) + "/" + str(sp["dpo_valid"])} sub="train/valid" dim={False} />
            <StatTile label="HOLDOUT" value={str(sp["holdout"])} sub="function" dim={False} />
            <StatTile label="HOLDOUT.GRAPH" value={str(sp["graph_holdout"])} sub="graph" dim={False} />
        </div>;
    }

    def _rail() -> JsxElement {
        nstages = len(builders) if len(builders) > 0 else 13;
        pct = (doneCount * 100.0) / nstages if nstages > 0 else 0.0;
        return <div className="relative rounded-md border border-border bg-card p-3 pt-4">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">PIPELINE</span>
            <div className="mb-3 flex flex-col gap-1.5">
                <div className="flex items-center justify-between">
                    <span className="stat-line text-muted-foreground">{str(doneCount)}/{str(nstages)} DONE</span>
                </div>
                <div className="h-1 w-full rounded-full bg-border">
                    <div className="h-1 rounded-full transition-all" style={{"width": str(pct) + "%", "background": "var(--ws-accent)"}}></div>
                </div>
            </div>
            <div className="relative flex flex-col gap-0.5 pl-3">
                <div className="absolute bottom-1 left-0 top-1 w-px bg-border"></div>
                {for group in GROUPS {
                    <div key={str(group["label"])} className="mt-2 first:mt-0">
                        <div className="mb-1 flex items-center gap-2">
                            <span className="micro-label shrink-0 text-muted-foreground/70">{str(group["label"])}</span>
                            <div className="dashed-rule flex-1"></div>
                        </div>
                        {for stage in list(group["stages"]) {
                            <div key={str(stage)}>
                                <div
                                    onClick={lambda e: MouseEvent { selectStage(str(stage)); }}
                                    className={"flex cursor-pointer items-center gap-2 rounded px-2 py-1 " + (
                                        "bg-accent" if selectedStage == str(stage) else "hover:bg-muted"
                                    )}
                                >
                                    <StatusGlyph status={_statusOf(str(stage))} showLabel={False} />
                                    <span className="flex-1 truncate font-mono text-xs text-muted-foreground">{str(stage)}</span>
                                    <Button
                                        variant="ghost"
                                        disabled={_statusOf(str(stage)) == "running"}
                                        onClick={lambda e: MouseEvent { e.stopPropagation(); runStage(str(stage)); }}
                                        className="px-1.5 py-0.5"
                                    >
                                        RUN
                                    </Button>
                                </div>
                                {(str(stage) == "seed_conversion") and <div className="stat-line ml-8 mt-0.5 mb-1 border-l-2 border-ring pl-2">TRUNCATES sft.jsonl→32 · dpo.jsonl→2 · run idiomatic batches after, then downstream stages</div>}
                            </div>
                        }}
                    </div>
                }}
            </div>
        </div>;
    }

    def _addExamples() -> JsxElement {
        ph = ('one JSON object per line · sft: {"messages":[...]}' if addTarget == "sft"
            else 'one JSON object per line · dpo: {"prompt","chosen","rejected"}');
        return <div className="relative rounded-md border border-border bg-card p-3 pt-4">
            <span className="micro-label absolute -top-2 left-3 bg-background px-2">ADD EXAMPLES</span>
            <div className="flex flex-col gap-3">
                <Segmented options={["sft", "dpo"]} value={addTarget} onSet={lambda v: str { addTarget = v; }} />
                <textarea
                    rows={6}
                    value={addText}
                    onChange={lambda e: ChangeEvent { addText = e.target.value; }}
                    placeholder={ph}
                    className="w-full rounded-md border border-input bg-popover px-2 py-1.5 font-mono text-xs text-foreground outline-none placeholder:text-muted-foreground/70 focus:border-ring resize-none"
                ></textarea>
                <Button
                    variant="solid"
                    disabled={addBusy or (not addText.strip())}
                    onClick={lambda e: MouseEvent { submitExamples(); }}
                    className="self-start py-1.5"
                >
                    {"APPENDING…" if addBusy else "APPEND"}
                </Button>
                {addResult and <div className="flex flex-col gap-2">
                    <div className="stat-line">added {str(addResult["added"])} · total {str(addResult["total"])}</div>
                    {(len(list(addResult["errors"])) > 0) and <LogView text={"\n".join([str(x) for x in list(addResult["errors"])])} maxH="8rem" />}
                </div>}
            </div>
        </div>;
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">DATA · SFT/DPO DATASET</span>
            {runningStage and <span key="running" className="micro-label pulse text-foreground/80">⦿ {runningStage}</span>}
        </div>
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            {_tiles()}
            <div className="grid gap-4" style={{"gridTemplateColumns": "280px 1fr"}}>
                <div className="flex flex-col gap-4">
                    {_rail()}
                    {selectedStage and <div className="relative rounded-md border border-border bg-card p-3 pt-4">
                        <span className="micro-label absolute -top-2 left-3 bg-background px-2">{selectedStage}</span>
                        <LogView text={_logOf(selectedStage)} maxH="14rem" />
                    </div>}
                </div>
                <div className="flex flex-col gap-4">
                    <RowBrowser
                        files={pager["files"]} path={pager["path"]} rows={pager["rows"]} offset={pager["offset"]}
                        total={pager["total"]} expanded={pager["expanded"]}
                        onOpen={pager["openFile"]} onToggle={pager["toggleRow"]}
                        onPrev={pager["prevPage"]} onNext={pager["nextPage"]}
                    />
                    {_addExamples()}
                </div>
            </div>
        </div>
    </div>;
}
