"""SectionHeader — the top bar every section hand-rolled 10×. title/right accept
elements (Train passes SubTabs as title)."""

def:pub SectionHeader(title: any = None, right: any = None) -> JsxElement {
    return <div className="section-header flex items-center justify-between border-b border-border px-4 py-2.5">
        <div className="flex items-center gap-3">{title}</div>
        <div className="flex items-center gap-3">{right}</div>
    </div>;
}
