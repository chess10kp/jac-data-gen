"""CareGapAlert component — care gap warning with recommended action."""

def:pub CareGapAlert(props: dict) -> JsxElement {
    gap = props.get("gap", {});
    severity = gap.get("severity", "LOW");

    low_style = "background:#f0fdf4;border-color:#86efac;color:#166534;";
    med_style = "background:#fefce8;border-color:#fde047;color:#854d0e;";
    high_style = "background:#fef2f2;border-color:#fca5a5;color:#dc2626;";
    crit_style = "background:#fff1f2;border-color:#fb7185;color:#be123c;";

    baseStyle = "border-radius:8px;padding:16px;border:1px solid;margin-bottom:8px;";
    colorStyle = crit_style
        if severity == "CRITICAL"
        else (
            high_style
                if severity == "HIGH"
                else (med_style if severity == "MEDIUM" else low_style)
        );
    cardStyle = baseStyle + colorStyle;

    days_overdue = gap.get("days_overdue", 0);

    return (
        <div style={_css(cardStyle)}>
            <div style={{"display": "flex", "justify-content": "space-between", "align-items": "center"}}>
                <span style={{"font-weight": "600", "font-size": "14px"}}>
                    {gap.get("gap_type")} Care Gap
                </span>
                <span style={{"font-size": "11px", "font-weight": "600", "text-transform": "uppercase"}}>
                    {severity}
                </span>
            </div>
            <p style={{"margin": "6px 0 0", "font-size": "13px"}}>
                {gap.get("recommended_action")}
            </p>
            {days_overdue > 0
                and (
                    <p style={{"margin": "4px 0 0", "font-size": "12px", "font-weight": "500"}}>
                        Overdue by {days_overdue} days
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

