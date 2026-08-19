"""DATA section (workspace 02 RL/GRPO) — read-only RL training-data browser.

Ports the RL half of the old blended Data section: the SFT gold / GRPO reward-task
/ python→jac / synthetic / splits sources (model-experiments/02-rl-grpo/dataset/…, via
rl_dataset_files/rl_dataset_rows in data.sv.jac) rendered through the shared
RowBrowser. No pipeline/add-examples here — those are 01-only.
"""

sv import from ...data { rl_dataset_files, rl_dataset_rows, FileRefView, DataRowView }
import from ..shared.Field { Segmented }
import from ..shared.RowBrowser { RowBrowser }
import from ...hooks.useRowPager { useRowPager }

glob RL_SOURCES: list[str] = ["SFT", "GRPO", "conversion", "synthetic", "splits"];

def:pub RlData -> JsxElement {
    has rlSource: str = "SFT";

    # `src` rides along explicitly on source switches (the hook's loadFiles ctx)
    # — reading rlSource right after setting it returns the stale value (React
    # state writes are async). Elsewhere (pager clicks, mount) src is None and
    # the current rlSource closure is fresh.
    async def _files(src: any = None) -> any {
        s = str(src) if src else rlSource;
        return await rl_dataset_files(s);
    }

    async def _rows(p: str, off: int, src: any = None) -> any {
        s = str(src) if src else rlSource;
        return await rl_dataset_rows(s, p, off, 25);
    }

    pager = useRowPager(_files, _rows);

    async def switchSource(s: str) -> None {
        rlSource = s;
        await pager["loadFiles"](s);
    }

    return <div className="flex h-full min-w-0 flex-1 flex-col">
        <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
            <span className="micro-label">DATA · RL TRAINING SETS (read-only)</span>
        </div>
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4">
            <div className="flex flex-wrap items-center gap-2">
                <span className="micro-label text-muted-foreground/70">SOURCE</span>
                <Segmented options={RL_SOURCES} value={rlSource} onSet={lambda v: str { switchSource(v); }} />
            </div>
            <div className="stat-line text-muted-foreground/70">RL training data (read-only) — SFT gold · GRPO reward tasks · python→jac · synthetic · splits. See RL_FINDINGS.md.</div>
            <RowBrowser
                files={pager["files"]} path={pager["path"]} rows={pager["rows"]} offset={pager["offset"]}
                total={pager["total"]} expanded={pager["expanded"]}
                onOpen={pager["openFile"]} onToggle={pager["toggleRow"]}
                onPrev={pager["prevPage"]} onNext={pager["nextPage"]}
            />
            <div className="stat-line text-muted-foreground/70">source: model-experiments/02-rl-grpo/dataset</div>
        </div>
    </div>;
}
