"""Shared dataset row browser: file chips + row table + expand-detail + pager.

Stateless props-component extracted from Data.cl.jac so the 01 (core), 02 (RL)
and 03 (CPT) DATA sections all render identical browsers over `DataRowView` rows.
The parent owns all state (files/path/rows/offset/total/expanded) and the fetch
handlers; this component only renders and calls back. No `has` state here → none
of the setX-collision gotchas apply.
"""

import from .CodeBlock { CodeBlock }
import from .Button { Button }
import from .Chip { Chip }

glob KIND_LABEL: dict = {
    "sft": "SFT", "dpo": "DPO", "holdout": "HOLD", "raw": "RAW", "rltask": "RL",
    "doc": "DOC", "code": "CODE", "blog": "BLOG", "paper": "PAPER", "rehearsal": "REHRS"
};

"""One expanded row's detail: structured code panes (sft/dpo/holdout/rltask) OR a
raw text block (cpt corpus rows + plain-json rows). Called with a props dict."""
def:pub RowDetail(row: any) -> JsxElement {
    kind = str(row["kind"]);
    structured = row["prompt"] or row["python"] or row["jac"] or row["chosen"];
    return <div className="rounded-md border border-border bg-card p-3 space-y-2">
        {row["prompt"] and <div>
            <div className="micro-label mb-1 text-muted-foreground/70">PROMPT</div>
            <pre className="whitespace-pre-wrap font-mono text-xs text-muted-foreground leading-relaxed">{row["prompt"]}</pre>
        </div>}
        {row["python"] and <CodeBlock label="" code={str(row["python"])} lang="python" />}
        {(row["jac"] and kind != "dpo") and <CodeBlock label="" code={str(row["jac"])} lang="jac" />}
        {(kind == "dpo" and row["chosen"]) and <CodeBlock label="CHOSEN.JAC" code={str(row["chosen"])} lang="jac" />}
        {(kind == "dpo" and row["rejected"]) and <CodeBlock label="REJECTED.JAC" code={str(row["rejected"])} lang="jac" />}
        {(row["raw"] and not structured) and <pre className="max-h-[32rem] overflow-y-auto whitespace-pre-wrap break-words font-mono text-xs text-muted-foreground leading-relaxed">{row["raw"]}</pre>}
    </div>;
}

"""File chips + row table + pager. Parent supplies state + callbacks:
onOpen(path), onToggle(idx), onPrev(), onNext()."""
def:pub RowBrowser(
    files: list, path: str, rows: list, offset: int, total: int, expanded: int,
    onOpen: any, onToggle: any, onPrev: any, onNext: any, label: str = "DATASET.BROWSER"
) -> JsxElement {
    canPrev = offset > 0;
    canNext = offset + len(rows) < total;
    return <div className="relative rounded-md border border-border bg-card p-3 pt-4">
        <span className="micro-label absolute -top-2 left-3 bg-background px-2">{label}</span>
        <div className="mb-3 flex flex-wrap gap-1">
            {(len(files) == 0) and <span className="stat-line">no files</span>}
            {for f in files {
                <Chip
                    key={str(f.path)}
                    onClick={lambda e: MouseEvent { onOpen(str(f.path)); }}
                    selected={str(f.path) == path}
                    className="rounded px-2 py-0.5 font-mono text-[10px]"
                >
                    {f.label} {str(f.count)}
                </Chip>
            }}
        </div>
        {path and <div>
            <div className="overflow-x-auto">
                <div className="mb-1 grid grid-cols-[2rem_1fr_3rem_3rem_5rem_1fr] gap-2">
                    <span className="micro-label">#</span>
                    <span className="micro-label">NAME</span>
                    <span className="micro-label">KIND</span>
                    <span className="micro-label">DIFF</span>
                    <span className="micro-label">SOURCE</span>
                    <span className="micro-label">PREVIEW</span>
                </div>
                {(len(rows) == 0) and <div className="stat-line py-4 text-center">empty</div>}
                {for row in rows {
                    <div key={str(row["idx"])}>
                        <div
                            onClick={lambda e: MouseEvent { onToggle(int(row["idx"])); }}
                            className="grid cursor-pointer grid-cols-[2rem_1fr_3rem_3rem_5rem_1fr] gap-2 rounded px-0.5 py-1 font-mono text-xs hover:bg-muted"
                        >
                            <span className="text-muted-foreground/70">{str(row["idx"])}</span>
                            <span className="truncate text-foreground/80">{row["name"]}</span>
                            <span className="text-muted-foreground">{str(KIND_LABEL[str(row["kind"])]) if str(row["kind"]) in KIND_LABEL else str(row["kind"])}</span>
                            <span className="text-muted-foreground">{row["difficulty"]}</span>
                            <span className="truncate text-muted-foreground">{row["source"]}</span>
                            <span className="truncate text-muted-foreground/70">{row["preview"]}</span>
                        </div>
                        {(expanded == int(row["idx"])) and <div className="mb-1">{RowDetail({"row": row})}</div>}
                    </div>
                }}
            </div>
            {(total > 0) and <div className="mt-3 flex items-center justify-center gap-3 stat-line">
                <Button variant="ghost" disabled={not canPrev} onClick={lambda e: MouseEvent { onPrev(); }}>← PREV</Button>
                <span>{str(offset + 1)} to {str(offset + len(rows))} of {str(total)}</span>
                <Button variant="ghost" disabled={not canNext} onClick={lambda e: MouseEvent { onNext(); }}>NEXT →</Button>
            </div>}
        </div>}
        {(not path) and <div className="stat-line py-6 text-center">select a file above</div>}
    </div>;
}
