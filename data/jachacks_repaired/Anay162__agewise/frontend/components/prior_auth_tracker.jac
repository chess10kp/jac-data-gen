"""PriorAuthTracker component — prior auth status pipeline visualization."""

def:pub PriorAuthTracker(props: dict) -> JsxElement {
    auth = props.get("prior_auth", {});
    status = auth.get("status", "PENDING");

    steps = ["PENDING", "UNDER_REVIEW", "DECIDED"];
    step_labels = {
        "PENDING": "Submitted",
        "UNDER_REVIEW": "Under Review",
        "DECIDED": "Decided"
    };

    current_idx = 0;
    if status == "UNDER_REVIEW" {
        current_idx = 1;
    } elif status == "DECIDED" {
        current_idx = 2;
    }

    decision = auth.get("decision", "Unknown");
    isApproved = decision == "APPROVED";
    decisionStyle = "margin-top:12px;padding:8px;border-radius:6px;text-align:center;font-size:13px;font-weight:600;"
        + (
            "background:#f0fdf4;color:#166534;"
                if isApproved
                else "background:#fef2f2;color:#dc2626;"
        );

    return (
        <div
            style={{"background": "white", "border-radius": "8px", "padding": "16px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
        >
            <div style={{"display": "flex", "justify-content": "space-between", "margin-bottom": "16px"}}>
                <span style={{"font-weight": "600", "font-size": "14px", "color": "#1e293b"}}>
                    {auth.get("medication_or_service", "Prior Authorization")}
                </span>
                <span style={{"font-size": "12px", "color": "#64748b"}}>
                    Auth # {auth.get("auth_number", "—")}
                </span>
            </div>
            <div style={{"display": "flex", "align-items": "center", "gap": "0"}}>
                {[
                    <div key={step} style={{"flex": "1", "text-align": "center"}}>
                        <div
                            style={_css("width:28px;height:28px;border-radius:50%;margin:0 auto;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;background:#3b82f6;color:white;"
                                if steps.index(step) <= current_idx
                                else "width:28px;height:28px;border-radius:50%;margin:0 auto;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;background:#e2e8f0;color:#94a3b8;")}
                        >
                            {steps.index(step) + 1}
                        </div>
                        <p
                            style={_css("margin:6px 0 0;font-size:11px;color:#3b82f6;font-weight:600;"
                                if steps.index(step) == current_idx
                                else "margin:6px 0 0;font-size:11px;color:#94a3b8;")}
                        >
                            {step_labels.get(step)}
                        </p>
                    </div> for step in steps
                ]}
            </div>
            {status == "DECIDED" and (<div style={_css(decisionStyle)}>{decision}</div>)}
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

