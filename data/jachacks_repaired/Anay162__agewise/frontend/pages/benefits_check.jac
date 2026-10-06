"""Benefits Check page — government benefit eligibility report and application status."""

import from graph.walkers.benefits.eligibility_screener { EligibilityScreener }
import from graph.walkers.benefits.benefits_report_generator { BenefitsReportGenerator }

def:pub BenefitsCheckPage() -> JsxElement {
    has eligibilities: list[dict] = [];
    has `report: dict = {};
    has loading: bool = True;
    has running_screen: bool = False;

    async can with entry {
        loading = False;
    }

    def fmt(v: float) -> str {
        return f"{v:.2f}";
    }

    def run_screening() {
        running_screen = True;
    }

    potentialValue = `report.get("total_potential_annual_value", 0);
    potentialValueFmt = fmt(potentialValue);
    screenBtnLabel = "Screening..." if running_screen else "Run Benefits Screen";

    return (
        <div className="benefits-page">
            <div style={{"display": "flex", "align-items": "center", "justify-content": "space-between", "margin-bottom": "24px"}}>
                <h2 style={{"margin": "0", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>Benefits Check</h2>
                <button
                    onClick={lambda (e: MouseEvent) { run_screening(); }}
                    style={{"background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "8px 16px", "font-size": "14px", "cursor": "pointer"}}
                >
                    {screenBtnLabel}
                </button>
            </div>

            {potentialValue > 0 and (
                <div style={{"background": "#eff6ff", "border": "1px solid #93c5fd", "border-radius": "8px", "padding": "20px", "margin-bottom": "24px"}}>
                    <p style={{"margin": "0", "font-size": "18px", "font-weight": "700", "color": "#1d4ed8"}}>
                        Potential Annual Value: ${potentialValueFmt}
                    </p>
                    <p style={{"margin": "8px 0 0", "font-size": "14px", "color": "#1e40af"}}>{`report.get("summary_text", "")}</p>
                </div>
            )}

            <div style={{"display": "flex", "flex-direction": "column", "gap": "12px"}}>
                {loading and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                {not loading and len(eligibilities) == 0 and (
                    <div style={{"background": "white", "border-radius": "8px", "padding": "40px", "text-align": "center", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}>
                        <p style={{"color": "#64748b", "font-size": "14px"}}>No screening results yet. Click "Run Benefits Screen" to check for programs like Extra Help, QMB, SNAP, and LIHEAP.</p>
                    </div>
                )}
                {not loading and len(eligibilities) > 0 and [
                    <div key={e.get("id")} style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}>
                        <div style={{"display": "flex", "justify-content": "space-between", "align-items": "center"}}>
                            <span style={{"font-weight": "600", "color": "#1e293b"}}>{e.get("program_name")}</span>
                            <span style={{"padding": "4px 10px", "border-radius": "9999px", "font-size": "12px", "font-weight": "600", "background": "#f0fdf4", "color": "#166534"} if e.get("is_eligible") else {"padding": "4px 10px", "border-radius": "9999px", "font-size": "12px", "font-weight": "600", "background": "#f1f5f9", "color": "#64748b"}}>
                                {"LIKELY ELIGIBLE" if e.get("is_eligible") else "NOT ELIGIBLE"}
                            </span>
                        </div>
                        {e.get("is_eligible") and (
                            <p style={{"margin": "8px 0 0", "font-size": "13px", "color": "#166534"}}>
                                Est. savings: ${fmt(e.get("estimated_savings_monthly", 0))}/month
                            </p>
                        )}
                        <p style={{"margin": "4px 0 0", "font-size": "13px", "color": "#64748b"}}>{e.get("eligibility_reason", "")}</p>
                        {e.get("is_eligible") and e.get("application_url") and (
                            <a href={e.get("application_url", "")} style={{"display": "inline-block", "margin-top": "8px", "font-size": "13px", "color": "#3b82f6"}}>
                                Apply Now →
                            </a>
                        )}
                    </div>
                    for e in eligibilities
                ]}
            </div>
        </div>
    );
}
