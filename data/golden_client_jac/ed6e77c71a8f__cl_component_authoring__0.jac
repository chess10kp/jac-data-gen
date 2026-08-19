"""SubTabs — dot-separated tab strip. Ports ui/components/shared/sub-tabs.tsx."""

def:pub SubTabs(tabs: list[str], active: str, onTab: Callable[([str], None)]) -> JsxElement {
    return <div className="flex items-center gap-0 border-b border-border pb-0">
        {for (i, t) in enumerate(tabs) {
            <span key={t} className="flex items-center">
                {i > 0 and <span className="micro-label px-2 text-muted-foreground/50">·</span>}
                <button
                    onClick={lambda e: MouseEvent { onTab(t); }}
                    className={"micro-label pb-1 transition-colors hover:text-foreground/80 " + (
                        "border-b-2 border-muted-foreground text-foreground" if active == t
                        else "text-muted-foreground/70"
                    )}
                >
                    {t}
                </button>
            </span>
        }}
    </div>;
}
