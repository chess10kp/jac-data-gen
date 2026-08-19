"""Chat right rail — prompt library + last-run stats.
Ports ui/components/rail.tsx (sampling now uses server defaults)."""

def _trunc(s: str) -> str {
    one = s.split(String.fromCharCode(10))[0];
    return (one[:54] + "…") if len(one) > 54 else one;
}

def:pub Rail(
    prompts: list, lastStats: any,
    collapsed: bool, onPick: Callable[([str], None)],
    onToggle: Callable[([], None)]
) -> JsxElement {
    has openCat: str = "py2jac";

    if collapsed {
        return <button
            onClick={lambda e: MouseEvent { onToggle(); }}
            className="flex w-8 shrink-0 items-center justify-center border-l border-border bg-card text-muted-foreground hover:text-foreground"
        >⟨</button>;
    }
    return <div className="flex w-60 shrink-0 flex-col overflow-y-auto border-l border-border bg-card">
        <div className="flex items-center justify-between border-b border-border px-3 py-2.5">
            <span className="micro-label">PROMPT LIBRARY</span>
            <button onClick={lambda e: MouseEvent { onToggle(); }} className="micro-label text-muted-foreground/70 hover:text-foreground/80">⟩</button>
        </div>
        <div className="p-2">
            {for cat in prompts {
                <div key={str(cat["id"])} className="mb-1">
                    <button
                        onClick={lambda e: MouseEvent { openCat = "" if openCat == str(cat["id"]) else str(cat["id"]); }}
                        className="flex w-full items-center justify-between rounded px-2 py-1 text-left font-mono text-[11px] text-foreground/80 hover:bg-muted"
                    >
                        <span>{("▾ " if openCat == str(cat["id"]) else "▸ ") + str(cat["label"])}</span>
                        <span className="text-muted-foreground/70">{str(len(list(cat["prompts"])))}</span>
                    </button>
                    {if openCat == str(cat["id"]) {
                        <div key="open" className="flex flex-col gap-0.5 pl-2">
                            {for (pi, pr) in enumerate(list(cat["prompts"])) {
                                <button
                                    key={str(pi)}
                                    onClick={lambda e: MouseEvent { onPick(str(pr)); }}
                                    className="truncate rounded px-2 py-1 text-left stat-line hover:bg-muted hover:text-foreground/80"
                                    title={str(pr)}
                                >{_trunc(str(pr))}</button>
                            }}
                        </div>
                        skip;
                    }}
                </div>
            }}
        </div>

        <div className="dashed-rule mx-3" />
        <div className="p-3">
            <div className="micro-label mb-2">LAST RUN</div>
            {if lastStats {
                <div key="stats" className="font-mono text-[11px] leading-relaxed text-muted-foreground">
                    <div>{str(lastStats["tps"])} tok/s</div>
                    <div>{str(lastStats["tokens"])} tokens</div>
                    <div>Δ {str(lastStats["gen_s"])}s · load {str(lastStats["load_s"])}s</div>
                </div>
                skip;
            }}
            {if not lastStats {
                <span key="none" className="stat-line">no run yet</span>
                skip;
            }}
        </div>
    </div>;
}
