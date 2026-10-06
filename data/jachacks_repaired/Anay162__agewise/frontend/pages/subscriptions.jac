"""Subscriptions page — subscription audit: charges, classification, cancellation approvals."""


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

import from graph.walkers.bills.subscription_audit_generator {
    SubscriptionAuditGenerator
}
import from graph.walkers.bills.subscription_canceller { SubscriptionCanceller }


def:pub SubscriptionsPage() -> JsxElement {
    has subscriptions: list = [];
    has audit: dict = {};
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    annualSavings = audit.get("estimated_annual_savings", 0);
    annualSavingsFmt = fmt(annualSavings);

    return (
        <div className="subscriptions-page">
            <h2 style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                Subscriptions
            </h2>
            {annualSavings > 0
                and (
                    <div
                        style={{"background": "#f0fdf4", "border": "1px solid #86efac", "border-radius": "8px", "padding": "16px", "margin-bottom": "24px"}}
                    >
                        <p
                            style={{"margin": "0", "font-size": "14px", "font-weight": "600", "color": "#166534"}}
                        >
                            Potential Annual Savings: ${annualSavingsFmt}
                        </p>
                        <p style={{"margin": "8px 0 0", "font-size": "13px", "color": "#166534"}}>
                            {audit.get("summary_text", "")}
                        </p>
                    </div>
                )}
            <div
                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
            >
                <div
                    style={{"display": "flex", "justify-content": "space-between", "align-items": "center", "margin-bottom": "16px"}}
                >
                    <h3 style={{"margin": "0", "font-size": "16px", "font-weight": "600"}}>
                        Recurring Subscriptions
                    </h3>
                </div>
                {loading and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                {not loading
                    and len(subscriptions) == 0
                    and (
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No subscriptions detected. Link a bank account to identify recurring charges.
                        </p>
                    )}
                {not loading
                    and len(subscriptions) > 0
                    and (
                        <div style={{"display": "flex", "flex-direction": "column", "gap": "8px"}}>
                            {[
                                <div
                                    key={s.get("id")}
                                    style={{"display": "flex", "justify-content": "space-between", "align-items": "center", "padding": "12px 0", "border-bottom": "1px solid #e2e8f0"}}
                                >
                                    <div>
                                        <p
                                            style={{"margin": "0", "font-weight": "500", "color": "#1e293b"}}
                                        >
                                            {s.get("service_name")}
                                        </p>
                                        <span
                                            style={_css("font-size:11px;padding:2px 6px;border-radius:9999px;background:#fef3c7;color:#92400e;"
                                                if s.get("classification") == "WASTEFUL"
                                                else "font-size:11px;padding:2px 6px;border-radius:9999px;background:#f0fdf4;color:#166534;")}
                                        >
                                            {s.get("classification", "UNKNOWN")}
                                        </span>
                                    </div>
                                    <div style={{"text-align": "right"}}>
                                        <p style={{"margin": "0", "font-weight": "600"}}>
                                            ${fmt(s.get("monthly_cost", 0))}/mo
                                        </p>
                                        {s.get("classification") == "WASTEFUL"
                                            and (
                                                <button
                                                    style={{"margin-top": "4px", "background": "#ef4444", "color": "white", "border": "none", "border-radius": "4px", "padding": "4px 8px", "font-size": "11px", "cursor": "pointer"}}
                                                >
                                                    Cancel
                                                </button>
                                            )}
                                    </div>
                                </div> for s in subscriptions
                            ]}
                        </div>
                    )}
            </div>
        </div>
    );
}
