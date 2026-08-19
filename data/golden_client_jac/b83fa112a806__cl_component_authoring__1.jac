"""StatusGlyph — status badge. Ports ui/components/shared/status-glyph.tsx.
Also covers the feed-liveness chip (live/stalled/nofeed) that Train and
CptTrain used to hand-roll identically; label overrides the status text."""

glob GLYPHS: dict = {
    "idle": "○", "running": "⦿", "done": "✓", "failed": "✗", "stopped": "◌", "finished": "✓",
    "live": "⦿", "stalled": "◍", "nofeed": "○"
};
# Semantic color: running/live = chart-1 (blue), done = success (green),
# failed = destructive (red), stalled = warning (amber); rest stay muted.
glob CLASSES: dict = {
    "idle": "text-muted-foreground/70", "running": "text-chart-1 pulse", "done": "text-success",
    "failed": "text-destructive", "stopped": "text-muted-foreground/70", "finished": "text-success",
    "live": "text-chart-1 pulse", "stalled": "text-warning", "nofeed": "text-muted-foreground/70"
};
glob LABELS: dict = {"nofeed": "NO FEED"};

def:pub StatusGlyph(status: str, showLabel: bool, label: str = "") -> JsxElement {
    glyph = str(GLYPHS[status]) if status in GLYPHS else "○";
    cls = str(CLASSES[status]) if status in CLASSES else "text-muted-foreground/70";
    failed = "border-b border-dashed border-destructive/50" if status == "failed" else "";
    text = label or (str(LABELS[status]) if status in LABELS else status.upper());
    return <span className={"font-mono text-[10px] tracking-widest " + cls + " " + failed}>
        {glyph}{(" " + text) if showLabel else ""}
    </span>;
}
