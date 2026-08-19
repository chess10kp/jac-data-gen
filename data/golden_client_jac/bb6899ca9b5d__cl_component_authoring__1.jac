"""Panel — bordered card with the floating micro-label. The ~25 hand-rolled
`relative rounded-md border … p-3 pt-4` + absolute-label blocks collapse onto
this. labelBg masks the border behind the label: bg-background on page-level
panels, bg-card when the panel sits inside a card surface."""

import from ...lib.utils { cn }

def:pub Panel(label: str, className: str = "", labelBg: str = "bg-background", children: any = None) -> JsxElement {
    return <div className={cn("relative rounded-md border border-border bg-card p-3 pt-4", className)}>
        {label and <span className={"micro-label absolute -top-2 left-3 px-2 " + labelBg}>{label}</span>}
        {children}
    </div>;
}
