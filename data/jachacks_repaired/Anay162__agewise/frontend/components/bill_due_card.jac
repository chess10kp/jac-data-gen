"""BillDueCard component — upcoming bill card with status and pay/snooze actions."""

def:pub BillDueCard(props: dict) -> JsxElement {
    bill = props.get("bill", {});
    on_pay: any = props.get("onPay");
    on_snooze: any = props.get("onSnooze");

    days_until = props.get("daysUntilDue", 0);
    is_overdue = days_until < 0;

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    urgencyStyle = "border-left:4px solid #ef4444;"
        if is_overdue
        else (
            "border-left:4px solid #f59e0b;"
                if days_until <= 3
                else "border-left:4px solid #e2e8f0;"
        );
    cardStyle = "background:white;border-radius:8px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,.1);"
        + urgencyStyle;
    amountFmt = fmt(float(bill.get("expected_amount", 0)));
    dueColor = "color:#ef4444;font-weight:600;" if is_overdue else "color:#64748b;";
    dueStyle = "margin:4px 0 0;font-size:12px;" + dueColor;
    absdays = abs(days_until);
    dueText = f"Overdue {absdays} days" if is_overdue else f"Due in {days_until} days";

    return (
        <div style={_css(cardStyle)}>
            <div
                style={{"display": "flex", "justify-content": "space-between", "align-items": "flex-start", "margin-bottom": "8px"}}
            >
                <div>
                    <p style={{"margin": "0", "font-weight": "600", "color": "#1e293b", "font-size": "14px"}}>
                        {bill.get("biller_name")}
                    </p>
                    <p style={{"margin": "4px 0 0", "font-size": "12px", "color": "#64748b"}}>
                        {bill.get("category")}
                    </p>
                </div>
                <div style={{"text-align": "right"}}>
                    <p style={{"margin": "0", "font-weight": "700", "font-size": "18px", "color": "#1e293b"}}>
                        ${amountFmt}
                    </p>
                    <p style={_css(dueStyle)}>{dueText}</p>
                </div>
            </div>
            <div style={{"display": "flex", "gap": "8px", "margin-top": "12px"}}>
                <button
                    onClick={on_pay}
                    style={{"flex": "2", "background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "7px", "font-size": "12px", "cursor": "pointer"}}
                >
                    Mark Paid
                </button>
                <button
                    onClick={on_snooze}
                    style={{"flex": "1", "background": "#f1f5f9", "color": "#64748b", "border": "none", "border-radius": "6px", "padding": "7px", "font-size": "12px", "cursor": "pointer"}}
                >
                    Snooze
                </button>
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

