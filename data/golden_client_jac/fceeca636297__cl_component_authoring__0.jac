"""Model picker pill + COMPARE popover — ports ui/components/model-pill.tsx.

The plain <select> is replaced by a rounded pill that opens a popover listing
every registered model with a status badge: `● LOADED` for the resident model,
`{size}GB` for an available-but-cold model, `MISSING` for one not on disk. While
a model is warming the pill shows `loading {label}… {n}s`. A second `⇄ COMPARE`
popover adds a vs-model so the next send streams both side-by-side.

Popovers are a relative trigger + an absolute panel; a fixed transparent overlay
behind the panel closes it on an outside click (no Radix dependency here)."""

def _label(models: list, mid: str) -> str {
    for m in models {
        if str(m.id) == mid { return str(m.label); }
    }
    return mid;
}

# Available models eligible as a COMPARE target (everything but the primary).
def _cmp_opts(models: list, modelId: str) -> list {
    return [m for m in models if m.available and str(m.id) != modelId];
}

def:pub ModelPill(
    models: list,
    modelId: str,
    compareId: str,
    loadedId: str,
    loadingId: str,
    loadElapsed: int,
    loadError: str,
    onPick: Callable[([str], None)],
    onPickCompare: Callable[([str], None)]
) -> JsxElement {
    has pickerOpen: bool = False,
        cmpOpen: bool = False;

    return <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
        <div className="flex items-center gap-2">
            <div className="relative">
                <button
                    onClick={lambda e: MouseEvent { pickerOpen = not pickerOpen; cmpOpen = False; }}
                    className="rounded-full border border-input bg-muted px-4 py-1 text-xs text-foreground hover:border-ring"
                >
                    {if loadingId {
                        <span key="loading">{"loading " + _label(models, loadingId) + "… " + str(loadElapsed) + "s"}</span>
                        skip;
                    }}
                    {if not loadingId {
                        <span key="ready">{_label(models, modelId)} <span className="text-muted-foreground">▾</span></span>
                        skip;
                    }}
                </button>
                {if pickerOpen {
                    <div key="overlay" className="fixed inset-0 z-10" onClick={lambda e: MouseEvent { pickerOpen = False; }} />
                    <div key="panel" className="absolute left-0 top-full z-20 mt-1 w-56 rounded-md border border-border bg-popover p-1">
                        {for m in models {
                            <button
                                key={str(m.id)}
                                disabled={not m.available}
                                onClick={lambda e: MouseEvent { onPick(str(m.id)); pickerOpen = False; }}
                                className="flex w-full items-center justify-between rounded px-2 py-1.5 text-left text-xs text-foreground/80 hover:bg-accent disabled:opacity-40"
                            >
                                <span>{str(m.label)}</span>
                                <span className="font-mono text-[9px] text-muted-foreground">
                                    {("● LOADED" if str(m.id) == loadedId else (str(m.size_gb) + "GB" if m.available else "MISSING"))}
                                </span>
                            </button>
                        }}
                    </div>
                    skip;
                }}
            </div>
            {compareId and <span className="font-mono text-[10px] text-muted-foreground">vs {_label(models, compareId)}</span>}
            {loadError and <span className="font-mono text-[10px] text-muted-foreground border border-dashed border-ring px-2 py-0.5">LOAD ERR: {loadError[:60]}</span>}
        </div>
        <div className="relative">
            <button
                onClick={lambda e: MouseEvent { cmpOpen = not cmpOpen; pickerOpen = False; }}
                className="micro-label hover:text-foreground/80"
            >{"⇄ COMPARE" + (" ·ON" if compareId else "")}</button>
            {if cmpOpen {
                <div key="overlay" className="fixed inset-0 z-10" onClick={lambda e: MouseEvent { cmpOpen = False; }} />
                <div key="panel" className="absolute right-0 top-full z-20 mt-1 w-56 rounded-md border border-border bg-popover p-1">
                    <button
                        onClick={lambda e: MouseEvent { onPickCompare(""); cmpOpen = False; }}
                        className="w-full rounded px-2 py-1.5 text-left text-xs text-muted-foreground hover:bg-accent"
                    >off</button>
                    {for m in _cmp_opts(models, modelId) {
                        <button
                            key={str(m.id)}
                            onClick={lambda e: MouseEvent { onPickCompare(str(m.id)); cmpOpen = False; }}
                            className="w-full rounded px-2 py-1.5 text-left text-xs text-foreground/80 hover:bg-accent"
                        >{str(m.label)}</button>
                    }}
                </div>
                skip;
            }}
        </div>
    </div>;
}
