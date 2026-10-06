"""Appointments page — upcoming/past appointments and care gap alerts."""

import from ..client.mock_data { USE_MOCK, MOCK_APPOINTMENTS, MOCK_CARE_GAPS }
import from ..components.appointment_card { AppointmentCard }
import from ..components.care_gap_alert { CareGapAlert }
import from ..graph.walkers.appointments.care_gap_detector { CareGapDetector }
import from "lucide-react" { Calendar, Loader2 }

def:pub Appointments() -> JsxElement {
    has appointments: list = [];
    has care_gaps:    list = [];
    has loading:      bool = True;

    async can with entry {
        if USE_MOCK {
            appointments = MOCK_APPOINTMENTS;
            care_gaps    = [g for g in MOCK_CARE_GAPS if not g["resolved"]];
        } else {
            result = root spawn CareGapDetector();
            if result.reports and len(result.reports) > 0 {
                data         = result.reports[0];
                appointments = data.get("appointments", []);
                care_gaps    = [g for g in data.get("care_gaps", []) if not g["resolved"]];
            }
        }
        loading = False;
    }

    if loading {
        return <div className="flex items-center justify-center h-64">
            <Loader2 className="w-8 h-8 text-primary-400 animate-spin" />
        </div>;
    }

    upcoming = sorted([a for a in appointments if a["status"] == "SCHEDULED"],
                      key=lambda (a: any) { a["appointment_date"] });
    past     = sorted([a for a in appointments if a["status"] == "COMPLETED"],
                      key=lambda (a: any) { a["appointment_date"] }, reverse=True);

    return <div className="max-w-4xl mx-auto space-y-6">
        <h1>Appointments</h1>

        {#* Care gaps *#}
        {<div>
            <h2 className="text-base font-semibold text-warm-900 mb-3 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-orange-500 animate-pulse" />
                Care Gaps Detected
            </h2>
            <div className="space-y-2">
                {[<CareGapAlert key={gap["gap_id"]} gap={gap} /> for gap in care_gaps]}
            </div>
        </div> if len(care_gaps) > 0 else <span></span>}

        {#* Upcoming *#}
        <div>
            <h2 className="text-base font-semibold text-warm-900 mb-3 flex items-center gap-2">
                <Calendar className="w-4 h-4 text-primary-500" />
                Upcoming ({len(upcoming)})
            </h2>
            {<div className="card text-center text-warm-500 py-10">No upcoming appointments scheduled.</div>
             if len(upcoming) == 0 else
             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[<AppointmentCard key={a["appointment_id"]} appt={a} /> for a in upcoming]}
             </div>}
        </div>

        {#* Past *#}
        {<div>
            <h2 className="text-base font-semibold text-warm-900 mb-3">Past Appointments</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[<AppointmentCard key={a["appointment_id"]} appt={a} /> for a in past[:4]]}
            </div>
        </div> if len(past) > 0 else <span></span>}

    </div>;
}
