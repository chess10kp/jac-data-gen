"""EmptyState — the one empty/loading vocabulary. pulse=True doubles as the
loading state (the app's aesthetic is text, not spinners)."""

def:pub EmptyState(label: str, hint: str = "", pulse: bool = False, height: int = 0) -> JsxElement {
    return <div
        className="flex flex-col items-center justify-center gap-1 py-6"
        style={{"height": height} if height > 0 else {}}
    >
        <span className={"micro-label " + ("pulse" if pulse else "")}>{label}</span>
        {hint and <span className="stat-line">{hint}</span>}
    </div>;
}
