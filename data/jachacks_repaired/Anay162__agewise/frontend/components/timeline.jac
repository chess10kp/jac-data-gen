"""Timeline component — chronological event display for claims, appeals, and actions."""

def:pub Timeline(props: dict) -> JsxElement {
    events: list = props.get("events", []);

    def getDotStyle(e: dict) -> str {
        return "position:absolute;left:-20px;top:4px;width:10px;height:10px;border-radius:50%;background:#3b82f6;"
            if e.get("type") == "action"
            else "position:absolute;left:-20px;top:4px;width:10px;height:10px;border-radius:50%;background:#94a3b8;";
    }

    return (
        <div className="timeline" style={{"position": "relative", "padding-left": "24px"}}>
            <div
                style={{"position": "absolute", "left": "8px", "top": "0", "bottom": "0", "width": "2px", "background": "#e2e8f0"}}
            ></div>
            {[
                <div key={e.get("id")} style={{"position": "relative", "margin-bottom": "20px"}}>
                    <div style={_css(getDotStyle(e))}></div>
                    <div>
                        <div style={{"display": "flex", "align-items": "baseline", "gap": "8px"}}>
                            <span style={{"font-size": "13px", "font-weight": "600", "color": "#1e293b"}}>
                                {e.get("title")}
                            </span>
                            <span style={{"font-size": "11px", "color": "#94a3b8"}}>
                                {e.get("date")}
                            </span>
                        </div>
                        {e.get("description")
                            and (
                                <p style={{"margin": "4px 0 0", "font-size": "13px", "color": "#64748b"}}>
                                    {e.get("description")}
                                </p>
                            )}
                    </div>
                </div> for e in events
            ]}
            {len(events) == 0
                and (
                    <p style={{"color": "#94a3b8", "font-size": "13px", "margin": "0"}}>
                        No events recorded yet.
                    </p>
                )}
        </div>
    );
}

def _css(s: any) -> dict[str, object] {
    out: dict[str, object] = {};
    for part in str(s).split(";") {
        part = part.strip();
        if not part { continue; }
        kv = part.split(":");
        if len(kv) < 2 { continue; }
        seg = kv[0].strip().split("-");
        camel = seg[0] + "".join([p.title() for p in seg[1:]]);
        out[camel] = ":".join(kv[1:]).strip();
    }
    return out;
}

