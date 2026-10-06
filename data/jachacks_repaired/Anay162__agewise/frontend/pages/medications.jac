"""Medications page — master med list, refill status, interaction warnings, prior auth tracker."""

import from graph.walkers.prescriptions.refill_tracker { RefillTracker }
import from graph.walkers.prescriptions.drug_interaction_checker {
    DrugInteractionChecker
}


def:pub MedicationsPage() -> JsxElement {
    has medications: list = [];
    has interactions: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    return (
        <div className="medications-page">
            <h2 style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                Medications
            </h2>
            {len(interactions) > 0
                and (
                    <div
                        style={{"background": "#fef2f2", "border": "1px solid #fca5a5", "border-radius": "8px", "padding": "16px", "margin-bottom": "24px"}}
                    >
                        <p
                            style={{"margin": "0", "font-size": "14px", "font-weight": "600", "color": "#dc2626"}}
                        >
                            Drug Interaction Warnings ({len(interactions)})
                        </p>
                        {[
                            <p
                                key={i.get("id")}
                                style={{"margin": "4px 0 0", "font-size": "13px", "color": "#dc2626"}}
                            >
                                {i.get("drug_a")} + {i.get("drug_b")}: {i.get(
                                    "severity"
                                )}
                            </p> for i in interactions
                        ]}
                    </div>
                )}
            <div
                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
            >
                <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                    Active Medications
                </h3>
                {loading and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                {not loading
                    and len(medications) == 0
                    and (
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No medications on file. Run the prescription pipeline or upload medication records.
                        </p>
                    )}
                {not loading
                    and len(medications) > 0
                    and (
                        <table
                            style={{"width": "100%", "border-collapse": "collapse", "font-size": "14px"}}
                        >
                            <thead>
                                <tr style={{"border-bottom": "2px solid #e2e8f0"}}>
                                    <th
                                        style={{"text-align": "left", "padding": "8px 0", "color": "#64748b", "font-weight": "600"}}
                                    >
                                        Drug Name
                                    </th>
                                    <th
                                        style={{"text-align": "left", "padding": "8px 0", "color": "#64748b", "font-weight": "600"}}
                                    >
                                        Strength
                                    </th>
                                    <th
                                        style={{"text-align": "left", "padding": "8px 0", "color": "#64748b", "font-weight": "600"}}
                                    >
                                        Refills
                                    </th>
                                    <th
                                        style={{"text-align": "left", "padding": "8px 0", "color": "#64748b", "font-weight": "600"}}
                                    >
                                        Next Fill
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {[
                                    <tr
                                        key={m.get("id")}
                                        style={{"border-bottom": "1px solid #e2e8f0"}}
                                    >
                                        <td style={{"padding": "12px 0", "font-weight": "500"}}>
                                            {m.get("drug_name")}
                                        </td>
                                        <td style={{"padding": "12px 0", "color": "#64748b"}}>
                                            {m.get("strength")}
                                        </td>
                                        <td style={{"padding": "12px 0", "color": "#64748b"}}>
                                            {m.get("refills_remaining", "—")}
                                        </td>
                                        <td style={{"padding": "12px 0", "color": "#64748b"}}>
                                            {m.get("next_fill_due", "—")}
                                        </td>
                                    </tr> for m in medications
                                ]}
                            </tbody>
                        </table>
                    )}
            </div>
        </div>
    );
}
