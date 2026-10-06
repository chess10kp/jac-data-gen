"""SubscriptionRow component — subscription item with classification badge and cancel toggle."""

def:pub SubscriptionRow(props: dict) -> JsxElement {
    sub = props.get("subscription", {});
    on_cancel: any = props.get("onCancel");
    classification = sub.get("classification", "UNKNOWN");

    badge_style = {
        "ESSENTIAL": "background:#f0fdf4;color:#166534;",
        "USEFUL": "background:#eff6ff;color:#1d4ed8;",
        "WASTEFUL": "background:#fef2f2;color:#dc2626;",
        "UNKNOWN": "background:#f1f5f9;color:#64748b;"
    };

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    badgeBaseStyle = "padding:3px 8px;border-radius:9999px;font-size:11px;font-weight:600;";
    badgeColor = "background:#f0fdf4;color:#166534;"
        if classification == "ESSENTIAL"
        else (
            "background:#eff6ff;color:#1d4ed8;"
                if classification == "USEFUL"
                else (
                    "background:#fef2f2;color:#dc2626;"
                        if classification == "WASTEFUL"
                        else "background:#f1f5f9;color:#64748b;"
                )
        );
    badgeFullStyle = badgeBaseStyle + badgeColor;
    monthlyCostFmt = fmt(float(sub.get("monthly_cost", 0)));
    annualCostFmt = fmt(float(sub.get("annual_cost", 0)));

    return (
        <div
            style={{"display": "flex", "align-items": "center", "padding": "12px 0", "border-bottom": "1px solid #e2e8f0", "gap": "12px"}}
        >
            <div style={{"flex": "2"}}>
                <p style={{"margin": "0", "font-weight": "500", "color": "#1e293b", "font-size": "14px"}}>
                    {sub.get("service_name")}
                </p>
                <p style={{"margin": "2px 0 0", "font-size": "12px", "color": "#94a3b8"}}>
                    Since {sub.get("first_seen_date", "—")}
                </p>
            </div>
            <span style={_css(badgeFullStyle)}>{classification}</span>
            <div style={{"text-align": "right", "min-width": "80px"}}>
                <p style={{"margin": "0", "font-weight": "600", "color": "#1e293b"}}>
                    ${monthlyCostFmt}/mo
                </p>
                <p style={{"margin": "2px 0 0", "font-size": "11px", "color": "#94a3b8"}}>
                    ${annualCostFmt}/yr
                </p>
            </div>
            {classification == "WASTEFUL"
                and (
                    <button
                        onClick={on_cancel}
                        style={{"background": "#fef2f2", "color": "#dc2626", "border": "1px solid #fca5a5", "border-radius": "6px", "padding": "5px 10px", "font-size": "11px", "cursor": "pointer", "white-space": "nowrap"}}
                    >
                        Cancel
                    </button>
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

