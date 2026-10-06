"""BenefitsEligibilityCard component — benefit program card with eligibility badge and apply button."""

def:pub BenefitsEligibilityCard(props: dict) -> JsxElement {
    elig = props.get("eligibility", {});
    on_apply: any = props.get("onApply");
    is_eligible = elig.get("is_eligible", False);

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    cardBorderStyle = "border-top:3px solid #22c55e;"
        if is_eligible
        else "border-top:3px solid #e2e8f0;";
    cardStyle = "background:white;border-radius:8px;padding:20px;box-shadow:0 1px 3px rgba(0,0,0,.1);"
        + cardBorderStyle;
    badgeStyle = "padding:4px 10px;border-radius:9999px;font-size:11px;font-weight:700;background:#f0fdf4;color:#166534;"
        if is_eligible
        else "padding:4px 10px;border-radius:9999px;font-size:11px;font-weight:700;background:#f1f5f9;color:#94a3b8;";
    badgeLabel = "LIKELY ELIGIBLE" if is_eligible else "NOT ELIGIBLE";
    savingsFmt = fmt(float(elig.get("estimated_savings_monthly", 0)));

    return (
        <div style={_css(cardStyle)}>
            <div
                style={{"display": "flex", "justify-content": "space-between", "align-items": "flex-start", "margin-bottom": "12px"}}
            >
                <h4 style={{"margin": "0", "font-size": "15px", "font-weight": "600", "color": "#1e293b"}}>
                    {elig.get("program_name")}
                </h4>
                <span style={_css(badgeStyle)}>{badgeLabel}</span>
            </div>
            {is_eligible
                and (
                    <p
                        style={{"margin": "0 0 8px", "font-size": "20px", "font-weight": "700", "color": "#22c55e"}}
                    >
                        $
                        {savingsFmt}
                        <span style={{"font-size": "13px", "font-weight": "400", "color": "#64748b"}}>
                            /month
                        </span>
                    </p>
                )}
            <p style={{"margin": "0", "font-size": "13px", "color": "#64748b", "line-height": "1.5"}}>
                {elig.get("eligibility_reason", "")}
            </p>
            {is_eligible
                and elig.get("application_url")
                and (
                    <button
                        onClick={on_apply}
                        style={{"margin-top": "16px", "width": "100%", "background": "#22c55e", "color": "white", "border": "none", "border-radius": "6px", "padding": "10px", "font-size": "14px", "font-weight": "600", "cursor": "pointer"}}
                    >
                        Apply Now
                    </button>
                )}
            {is_eligible
                and elig.get("application_phone")
                and (
                    <p
                        style={{"margin": "8px 0 0", "text-align": "center", "font-size": "12px", "color": "#64748b"}}
                    >
                        or call {elig.get("application_phone")}
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

