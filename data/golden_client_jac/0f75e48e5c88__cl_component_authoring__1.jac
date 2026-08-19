"""LogView — reversed monospace log with error/prompt line coloring.
Ports ui/components/shared/log-view.tsx."""

def _lineClass(ln: str) -> str {
    low = ln.lower();
    if "error" in low or "✗" in ln or "traceback" in low {
        return "text-foreground";
    }
    if ln.startswith(">>>") {
        return "text-foreground/80";
    }
    return "text-muted-foreground";
}

def:pub LogView(text: str, maxH: str) -> JsxElement {
    nl = String.fromCharCode(10);
    lines = text.split(nl);
    lines.reverse();
    return <pre
        className="flex flex-col-reverse overflow-y-auto rounded-md border border-border bg-card p-3 font-mono text-[11px] leading-relaxed"
        style={{"maxHeight": maxH}}
    >
        {for (i, ln) in enumerate(lines) {
            <div key={str(i)} className={_lineClass(ln)}>{ln if ln else " "}</div>
        }}
    </pre>;
}
