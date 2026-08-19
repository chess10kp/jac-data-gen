"""Button — the one action button. Three variants cover every current use:
outline (default chrome action), solid (the section's primary action), ghost
(inline micro-actions like COPY/DEL). One size; pass className for width tweaks."""

import from ...lib.utils { cn }

glob VARIANTS: dict = {
    "outline": "border border-ring text-foreground hover:bg-muted",
    "solid": "border border-ring bg-accent text-foreground hover:bg-muted",
    "ghost": "border border-transparent text-muted-foreground hover:text-foreground"
};

def:pub Button(
    onClick: Callable[([MouseEvent], None)],
    children: any = None,
    variant: str = "outline",
    disabled: bool = False,
    className: str = ""
) -> JsxElement {
    v = str(VARIANTS[variant]) if variant in VARIANTS else str(VARIANTS["outline"]);
    return <button
        onClick={onClick}
        disabled={disabled}
        className={cn(
            "rounded-md px-3 py-1 font-mono text-[10px] tracking-[0.15em] uppercase transition-colors",
            v,
            "cursor-not-allowed opacity-40" if disabled else "",
            className
        )}
    >
        {children}
    </button>;
}
