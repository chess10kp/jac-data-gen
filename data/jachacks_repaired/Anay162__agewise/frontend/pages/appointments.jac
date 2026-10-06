"""Appointments page — calendar view, care gap warnings, and reschedule actions."""

import from graph.walkers.appointments.appointment_sync { AppointmentSync }
import from graph.walkers.appointments.care_gap_detector { CareGapDetector }


def:pub AppointmentsPage() -> JsxElement {
    has appointments: list = [];
    has care_gaps: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    return (
        <div className="appointments-page">
            <h2 style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                Appointments
            </h2>
            {len(care_gaps) > 0
                and (
                    <div
                        style={{"background": "#fef2f2", "border": "1px solid #fca5a5", "border-radius": "8px", "padding": "16px", "margin-bottom": "24px"}}
                    >
                        <p
                            style={{"margin": "0", "font-size": "14px", "font-weight": "600", "color": "#dc2626"}}
                        >
                            Care Gap Alerts ({len(care_gaps)})
                        </p>
                        {[
                            <p
                                key={g.get("id")}
                                style={{"margin": "4px 0 0", "font-size": "13px", "color": "#dc2626"}}
                            >
                                {g.get("gap_type")}: overdue by {g.get(
                                    "days_overdue", 0
                                )} days
                            </p> for g in care_gaps
                        ]}
                    </div>
                )}
            <div
                style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)", "margin-bottom": "16px"}}
            >
                <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                    Upcoming Appointments
                </h3>
                {loading and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                {not loading
                    and len(appointments) == 0
                    and (
                        <p style={{"color": "#64748b", "font-size": "14px"}}>
                            No upcoming appointments. Connect your health portal to sync appointments.
                        </p>
                    )}
                {not loading
                    and len(appointments) > 0
                    and (
                        <div style={{"display": "flex", "flex-direction": "column", "gap": "12px"}}>
                            {[
                                <div
                                    key={a.get("id")}
                                    style={{"border": "1px solid #e2e8f0", "border-radius": "6px", "padding": "16px"}}
                                >
                                    <div
                                        style={{"display": "flex", "justify-content": "space-between"}}
                                    >
                                        <span style={{"font-weight": "600", "color": "#1e293b"}}>
                                            {a.get("provider_name")}
                                        </span>
                                        <span style={{"font-size": "12px", "color": "#64748b"}}>
                                            {a.get("appointment_date")}
                                        </span>
                                    </div>
                                    <p
                                        style={{"margin": "4px 0 0", "font-size": "13px", "color": "#64748b"}}
                                    >
                                        {a.get("facility_name")} — {a.get("specialty")}
                                    </p>
                                </div> for a in appointments
                            ]}
                        </div>
                    )}
            </div>
        </div>
    );
}
