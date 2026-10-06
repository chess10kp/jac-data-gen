"""DisputeCard component — dispute summary with status badge and action buttons."""

def:pub DisputeCard(props: dict) -> JsxElement {
    dispute = props.get("dispute", {});
    status = dispute.get("status", "OPEN");
    status_colors = {
        "OPEN": "background:#fef3c7;color:#92400e;",
        "IN_PROGRESS": "background:#eff6ff;color:#1d4ed8;",
        "APPEALED": "background:#f0fdf4;color:#166534;",
        "RESOLVED": "background:#f1f5f9;color:#475569;"
    };

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    statusColor = "background:#fef3c7;color:#92400e;"
        if status == "OPEN"
        else (
            "background:#eff6ff;color:#1d4ed8;"
                if status == "IN_PROGRESS"
                else (
                    "background:#f0fdf4;color:#166534;"
                        if status == "APPEALED"
                        else "background:#f1f5f9;color:#475569;"
                )
        );
    statusStyle = "padding:3px 10px;border-radius:9999px;font-size:11px;font-weight:600;"
        + statusColor;
    amountFmt = fmt(float(dispute.get("amount_disputed", 0)));

    return (
        <div
            style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)", "border-left": "4px solid #ef4444"}}
        >
            <div
                style={{"display": "flex", "justify-content": "space-between", "align-items": "center", "margin-bottom": "12px"}}
            >
                <span style={{"font-weight": "600", "color": "#1e293b", "font-size": "15px"}}>
                    {dispute.get("error_type", "Billing Error")}
                </span>
                <span style={_css(statusStyle)}>{status}</span>
            </div>
            <div
                style={{"display": "grid", "grid-template-columns": "1fr 1fr", "gap": "8px", "margin-bottom": "12px"}}
            >
                <div>
                    <p
                        style={{"margin": "0", "font-size": "11px", "color": "#94a3b8", "text-transform": "uppercase"}}
                    >
                        Amount Disputed
                    </p>
                    <p
                        style={{"margin": "4px 0 0", "font-size": "18px", "font-weight": "700", "color": "#ef4444"}}
                    >
                        ${amountFmt}
                    </p>
                </div>
                <div>
                    <p
                        style={{"margin": "0", "font-size": "11px", "color": "#94a3b8", "text-transform": "uppercase"}}
                    >
                        Appeal Level
                    </p>
                    <p
                        style={{"margin": "4px 0 0", "font-size": "18px", "font-weight": "700", "color": "#1e293b"}}
                    >
                        L{dispute.get("appeal_level", 1)}
                    </p>
                </div>
            </div>
            <p style={{"margin": "0", "font-size": "13px", "color": "#64748b"}}>
                {dispute.get("error_description", "")}
            </p>
            {dispute.get("deadline")
                and (
                    <p
                        style={{"margin": "8px 0 0", "font-size": "12px", "color": "#f59e0b", "font-weight": "500"}}
                    >
                        Deadline: {dispute.get("deadline")}
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

