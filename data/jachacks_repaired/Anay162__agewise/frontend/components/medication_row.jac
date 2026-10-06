"""MedicationRow component — medication list row with refill status and interaction icon."""

def:pub MedicationRow(props: dict) -> JsxElement {
    med = props.get("medication", {});
    rx = props.get("prescription", {});
    has_interaction = props.get("hasInteraction", False);

    days_rem = int(rx.get("days_remaining", 0) or 0);
    days_sup = int(rx.get("days_supply", 30) or 30);

    refill_pct = 100;
    if days_sup > 0 {
        refill_pct = min(100, int(days_rem * 100 / days_sup));
    }

    bar_color = "#22c55e"
        if refill_pct > 30
        else ("#f59e0b" if refill_pct > 10 else "#ef4444");
    barStyle = "height:100%;border-radius:9999px;width:"
        + str(refill_pct)
        + "%;background:"
        + bar_color
        + ";";

    return (
        <div
            style={{"display": "flex", "align-items": "center", "padding": "12px 0", "border-bottom": "1px solid #e2e8f0", "gap": "16px"}}
        >
            <div style={{"flex": "2"}}>
                <div style={{"display": "flex", "align-items": "center", "gap": "6px"}}>
                    <span style={{"font-weight": "500", "color": "#1e293b", "font-size": "14px"}}>
                        {med.get("drug_name")}
                    </span>
                    {has_interaction
                        and (
                            <span
                                style={{"background": "#fef2f2", "color": "#dc2626", "font-size": "10px", "font-weight": "700", "padding": "1px 5px", "border-radius": "4px"}}
                                title="Drug interaction warning"
                            >
                                ⚠
                            </span>
                        )}
                </div>
                <p style={{"margin": "2px 0 0", "font-size": "12px", "color": "#64748b"}}>
                    {med.get("strength")} — {med.get("therapeutic_class")}
                </p>
            </div>
            <div style={{"flex": "1"}}>
                <div
                    style={{"background": "#e2e8f0", "border-radius": "9999px", "height": "6px", "overflow": "hidden"}}
                >
                    <div style={_css(barStyle)}></div>
                </div>
                <p style={{"margin": "4px 0 0", "font-size": "11px", "color": "#64748b"}}>
                    {days_rem} days left
                </p>
            </div>
            <div style={{"flex": "1", "text-align": "right"}}>
                <p style={{"margin": "0", "font-size": "12px", "color": "#64748b"}}>
                    Next fill: {rx.get("next_fill_due", "—")}
                </p>
                <p style={{"margin": "2px 0 0", "font-size": "12px", "color": "#64748b"}}>
                    {rx.get("refills_remaining", 0)} refills left
                </p>
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

