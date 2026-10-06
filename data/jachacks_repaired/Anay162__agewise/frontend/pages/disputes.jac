"""Disputes page — active billing disputes and appeal status tracking."""

import from graph.walkers.disputes.dispute_creator { DisputeCreator }
import from graph.walkers.disputes.appeal_tracker { AppealTracker }


def:pub DisputesPage() -> JsxElement {
    has disputes: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    return (
        <div className="disputes-page">
            <div
                style={{"display": "flex", "align-items": "center", "justify-content": "space-between", "margin-bottom": "24px"}}
            >
                <h2 style={{"margin": "0", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                    Disputes & Appeals
                </h2>
                <button
                    style={{"background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "8px 16px", "font-size": "14px", "cursor": "pointer"}}
                >
                    Run Dispute Check
                </button>
            </div>
            {loading and <p style={{"color": "#64748b"}}>Loading disputes...</p>}
            {not loading
                and len(disputes) == 0
                and (
                    <div
                        style={{"background": "white", "border-radius": "8px", "padding": "40px", "text-align": "center", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                    >
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No active disputes found. Upload an EOB or bill to check for errors.
                        </p>
                    </div>
                )}
            {not loading
                and len(disputes) > 0
                and (
                    <div style={{"display": "flex", "flex-direction": "column", "gap": "12px"}}>
                        {[
                            <div
                                key={d.get("id")}
                                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                            >
                                <div
                                    style={{"display": "flex", "justify-content": "space-between", "align-items": "center"}}
                                >
                                    <span style={{"font-weight": "600", "color": "#1e293b"}}>
                                        {d.get("error_type")}
                                    </span>
                                    <span
                                        style={{"background": "#fef3c7", "color": "#92400e", "padding": "2px 8px", "border-radius": "9999px", "font-size": "12px"}}
                                    >
                                        {d.get("status")}
                                    </span>
                                </div>
                                <p style={{"margin": "8px 0 0", "font-size": "14px", "color": "#64748b"}}>
                                    Amount: ${fmt(d.get("amount", 0))}
                                </p>
                            </div> for d in disputes
                        ]}
                    </div>
                )}
        </div>
    );
}
