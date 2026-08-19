"""Chip — selectable pill (segmented options, session pickers, file chips,
history model/stage buttons). Selected = accent surface + the workspace accent
color on the border (second state channel beyond tone)."""

import from ...lib.utils { cn }

def:pub Chip(
    onClick: Callable[([MouseEvent], None)],
    selected: bool = False,
    children: any = None,
    className: str = ""
) -> JsxElement {
    return <button
        onClick={onClick}
        style={{"borderColor": "var(--ws-accent)"} if selected else {}}
        className={cn(
            "rounded-md border px-3 py-1 text-xs transition-colors",
            "bg-accent text-foreground" if selected
                else "border-input text-muted-foreground hover:text-foreground/80",
            className
        )}
    >
        {children}
    </button>;
}
