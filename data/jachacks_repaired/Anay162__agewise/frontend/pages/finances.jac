"""Finances page — linked accounts, transaction history, and anomaly alerts."""

import from graph.walkers.bills.payment_anomaly_detector { PaymentAnomalyDetector }


def:pub FinancesPage() -> JsxElement {
    has accounts: list = [];
    has transactions: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    return (
        <div className="finances-page">
            <div
                style={{"display": "flex", "align-items": "center", "justify-content": "space-between", "margin-bottom": "24px"}}
            >
                <h2 style={{"margin": "0", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                    Finances
                </h2>
                <button
                    style={{"background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "8px 16px", "font-size": "14px", "cursor": "pointer"}}
                >
                    Link Account
                </button>
            </div>
            {loading and <p style={{"color": "#64748b"}}>Loading accounts...</p>}
            {not loading
                and len(accounts) == 0
                and (
                    <div
                        style={{"background": "white", "border-radius": "8px", "padding": "40px", "text-align": "center", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                    >
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No accounts linked. Connect a bank account to monitor medical charges and subscriptions.
                        </p>
                        <button
                            style={{"margin-top": "16px", "background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "10px 20px", "font-size": "14px", "cursor": "pointer"}}
                        >
                            Connect with Plaid
                        </button>
                    </div>
                )}
        </div>
    );
}
