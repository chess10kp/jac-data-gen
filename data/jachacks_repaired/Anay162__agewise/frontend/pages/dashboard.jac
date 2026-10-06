"""Dashboard page — patient overview with summary stats and recent activity."""

import from graph.walkers.intake.digest_generator { DigestGenerator }


def:pub Dashboard() -> JsxElement {
    has summary: dict = {};
    has loading: bool = True;

    async can with entry {
        loading = False;
        summary = {
            "claims": 0,
            "open_disputes": 0,
            "total_disputed": 0.0,
            "appeal_deadlines": 0
        };
    }

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    totalDisputed = fmt(summary.get("total_disputed", 0.0));

    return (
        <div className="dashboard-page">
            {loading and <p style={{"color": "#64748b"}}>Loading dashboard...</p>}{not loading
                and (
                    <div>
                        <h2
                            style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}
                        >
                            Dashboard
                        </h2>
                        <div
                            style={{"display": "grid", "grid-template-columns": "repeat(4,1fr)", "gap": "16px", "margin-bottom": "32px"}}
                        >
                            <div
                                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                            >
                                <p
                                    style={{"margin": "0", "font-size": "12px", "color": "#64748b", "text-transform": "uppercase", "letter-spacing": ".05em"}}
                                >
                                    Total Claims
                                </p>
                                <p
                                    style={{"margin": "8px 0 0", "font-size": "32px", "font-weight": "700", "color": "#1e293b"}}
                                >
                                    {summary.get("claims", 0)}
                                </p>
                            </div>
                            <div
                                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                            >
                                <p
                                    style={{"margin": "0", "font-size": "12px", "color": "#64748b", "text-transform": "uppercase", "letter-spacing": ".05em"}}
                                >
                                    Open Disputes
                                </p>
                                <p
                                    style={{"margin": "8px 0 0", "font-size": "32px", "font-weight": "700", "color": "#ef4444"}}
                                >
                                    {summary.get("open_disputes", 0)}
                                </p>
                            </div>
                            <div
                                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                            >
                                <p
                                    style={{"margin": "0", "font-size": "12px", "color": "#64748b", "text-transform": "uppercase", "letter-spacing": ".05em"}}
                                >
                                    Amount Disputed
                                </p>
                                <p
                                    style={{"margin": "8px 0 0", "font-size": "32px", "font-weight": "700", "color": "#f59e0b"}}
                                >
                                    ${totalDisputed}
                                </p>
                            </div>
                            <div
                                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                            >
                                <p
                                    style={{"margin": "0", "font-size": "12px", "color": "#64748b", "text-transform": "uppercase", "letter-spacing": ".05em"}}
                                >
                                    Appeal Deadlines
                                </p>
                                <p
                                    style={{"margin": "8px 0 0", "font-size": "32px", "font-weight": "700", "color": "#8b5cf6"}}
                                >
                                    {summary.get("appeal_deadlines", 0)}
                                </p>
                            </div>
                        </div>
                        <div
                            style={{"background": "white", "border-radius": "8px", "padding": "24px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                        >
                            <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                                Recent Activity
                            </h3>
                            <p style={{"color": "#64748b", "font-size": "14px"}}>
                                No recent activity. Upload a document or connect your Medicare account to get started.
                            </p>
                        </div>
                    </div>
                )}
        </div>
    );
}
