"""RefillCountdown component — prescription refill countdown indicator."""

def:pub RefillCountdown(props: dict) -> JsxElement {
    days_remaining = props.get("daysRemaining", 0);
    drug_name = props.get("drugName", "");
    is_overdue = days_remaining < 0;

    color = "#22c55e"
        if days_remaining > 14
        else "#f59e0b" if days_remaining > 0 else "#ef4444";
    label = f"{abs(days_remaining)} days overdue"
        if is_overdue
        else f"{days_remaining} days until refill";

    return (
        <div style={{"display": "inline-flex", "align-items": "center", "gap": "8px"}}>
            <div
                style={_css(f"width:36px;height:36px;border-radius:50%;background:{color}20;border:3px solid {color};display:flex;align-items:center;justify-content:center;")}
            >
                <span style={_css(f"font-size:11px;font-weight:700;color:{color};")}>
                    {abs(days_remaining)}
                </span>
            </div>
            <div>
                <p style={{"margin": "0", "font-size": "12px", "font-weight": "500", "color": "#1e293b"}}>
                    {drug_name}
                </p>
                <p style={_css(f"margin:2px 0 0;font-size:11px;color:{color};")}>{label}</p>
            </div>
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

