"""AppointmentCard component — appointment summary with countdown and actions."""

def:pub AppointmentCard(props: dict) -> JsxElement {
    appt = props.get("appointment", {});
    on_reschedule: any = props.get("onReschedule");

    return (
        <div
            style={{"background": "white", "border-radius": "8px", "padding": "16px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)", "border-left": "4px solid #3b82f6"}}
        >
            <div
                style={{"display": "flex", "justify-content": "space-between", "align-items": "flex-start"}}
            >
                <div>
                    <p style={{"margin": "0", "font-weight": "600", "color": "#1e293b", "font-size": "15px"}}>
                        {appt.get("provider_name")}
                    </p>
                    <p style={{"margin": "4px 0 0", "font-size": "13px", "color": "#64748b"}}>
                        {appt.get("specialty")} — {appt.get("facility_name")}
                    </p>
                </div>
                <div style={{"text-align": "right"}}>
                    <p style={{"margin": "0", "font-weight": "600", "color": "#3b82f6", "font-size": "14px"}}>
                        {appt.get("appointment_date")}
                    </p>
                    <p style={{"margin": "4px 0 0", "font-size": "12px", "color": "#64748b"}}>
                        {appt.get("appointment_time")}
                    </p>
                </div>
            </div>
            <div style={{"display": "flex", "gap": "8px", "margin-top": "12px"}}>
                <button
                    style={{"flex": "1", "background": "#f1f5f9", "color": "#475569", "border": "none", "border-radius": "6px", "padding": "6px 12px", "font-size": "12px", "cursor": "pointer"}}
                >
                    Add to Calendar
                </button>
                <button
                    onClick={on_reschedule}
                    style={{"flex": "1", "background": "#fef3c7", "color": "#92400e", "border": "none", "border-radius": "6px", "padding": "6px 12px", "font-size": "12px", "cursor": "pointer"}}
                >
                    Reschedule
                </button>
            </div>
        </div>
    );
}
