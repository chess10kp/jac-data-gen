"""Bills & Payments page — upcoming bills, overdue alerts, payment history."""

import from graph.walkers.bills.bill_due_date_tracker { BillDueDateTracker }
import from graph.walkers.bills.missed_payment_detector { MissedPaymentDetector }


def:pub BillsPaymentsPage() -> JsxElement {
    has bills: list = [];
    has missed: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    return (
        <div className="bills-page">
            <h2 style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                Bills & Payments
            </h2>
            {len(missed) > 0
                and (
                    <div
                        style={{"background": "#fef2f2", "border": "1px solid #fca5a5", "border-radius": "8px", "padding": "16px", "margin-bottom": "24px"}}
                    >
                        <p
                            style={{"margin": "0", "font-size": "14px", "font-weight": "600", "color": "#dc2626"}}
                        >
                            Missed Payments ({len(missed)})
                        </p>
                        {[
                            <p
                                key={m.get("id")}
                                style={{"margin": "4px 0 0", "font-size": "13px", "color": "#dc2626"}}
                            >
                                {m.get("biller_name")}: was due {m.get("due_date")}
                            </p> for m in missed
                        ]}
                    </div>
                )}
            <div
                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
            >
                <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                    Recurring Bills
                </h3>
                {loading and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                {not loading
                    and len(bills) == 0
                    and (
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No recurring bills detected. Link a bank account to automatically identify recurring charges.
                        </p>
                    )}
                {not loading
                    and len(bills) > 0
                    and (
                        <div style={{"display": "flex", "flex-direction": "column", "gap": "8px"}}>
                            {[
                                <div
                                    key={b.get("id")}
                                    style={{"display": "flex", "justify-content": "space-between", "align-items": "center", "padding": "12px 0", "border-bottom": "1px solid #e2e8f0"}}
                                >
                                    <div>
                                        <p
                                            style={{"margin": "0", "font-weight": "500", "color": "#1e293b"}}
                                        >
                                            {b.get("biller_name")}
                                        </p>
                                        <p
                                            style={{"margin": "4px 0 0", "font-size": "12px", "color": "#64748b"}}
                                        >
                                            {b.get("category")} — Due: {b.get(
                                                "next_due_date"
                                            )}
                                        </p>
                                    </div>
                                    <span style={{"font-weight": "600", "color": "#1e293b"}}>
                                        ${fmt(b.get("expected_amount", 0))}
                                    </span>
                                </div> for b in bills
                            ]}
                        </div>
                    )}
            </div>
        </div>
    );
}
