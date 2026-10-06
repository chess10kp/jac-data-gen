"""Card for a single appointment with countdown and location details."""

import from components.status_badge { StatusBadge }

import from "lucide-react" { Calendar, MapPin, Clock, User }

def:pub AppointmentCard(props: dict) -> JsxElement {
    appt = props.get("appt", {});
    days = int(appt.get("days_until_appt", 999) or 999);
    is_past = days < 0;

    card_cls = f"card flex flex-col gap-3 {'opacity-70' if is_past else ''}";
    countdown_lbl = "Today"
        if days == 0
        else ("Tomorrow" if days == 1 else f"In {days} days");
    countdown_cls = f"text-xs font-medium {'text-orange-600'
        if days <= 3
        else 'text-warm-500'}";
    show_countdown = not is_past and str(appt.get("status", "")) == "SCHEDULED";
    date_display = str(appt.get("appointment_date", ""));

    return
        <div className={card_cls}>
            <div className="flex items-start justify-between gap-2">
                <div>
                    <div className="font-semibold text-warm-900">
                        {appt.get("provider_name", "")}
                    </div>
                    <div className="text-sm text-warm-500">
                        {appt.get("specialty", "")}
                    </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                    <StatusBadge status={appt.get("status", "")}/>
                    {<span className={countdown_cls}>{countdown_lbl}</span>
                        if show_countdown
                        else <span></span>}
                </div>
            </div>
            <div className="space-y-1.5 text-sm text-warm-600">
                <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-warm-400 flex-shrink-0"/>
                    <span>{date_display}</span>
                    {<span className="flex items-center gap-1 ml-1">
                        <Clock className="w-4 h-4 text-warm-400 flex-shrink-0"/>
                        {appt.get("appointment_time", "")}
                    </span>
                        if appt.get("appointment_time")
                        else <span></span>}
                </div>
                {<div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-warm-400 flex-shrink-0"/>
                    <span>{appt.get("facility_name", "")}</span>
                </div>
                    if appt.get("facility_name")
                    else <span></span>}
                {<div className="flex items-center gap-2">
                    <User className="w-4 h-4 text-warm-400 flex-shrink-0"/>
                    <span>{appt.get("purpose", "")}</span>
                </div>
                    if appt.get("purpose")
                    else <span></span>}
            </div>
        </div>;
}
