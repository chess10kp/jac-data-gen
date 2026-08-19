"""StatTile — corner-bracket stat box. Ports ui/components/shared/stat-tile.tsx."""

def:pub StatTile(label: str, value: str, sub: str, dim: bool) -> JsxElement {
    return <div className={"relative p-3 pt-4 " + ("opacity-40" if dim else "")}>
        <span className="absolute left-0 top-0 h-[10px] w-[10px] border-l border-t border-ring" />
        <span className="absolute right-0 top-0 h-[10px] w-[10px] border-r border-t border-ring" />
        <span className="absolute bottom-0 left-0 h-[10px] w-[10px] border-b border-l border-ring" />
        <span className="absolute bottom-0 right-0 h-[10px] w-[10px] border-b border-r border-ring" />
        <div className="micro-label mb-1">{label}</div>
        <div className="font-mono text-xl text-foreground">{value}</div>
        {sub and <div className="stat-line mt-0.5">{sub}</div>}
    </div>;
}
