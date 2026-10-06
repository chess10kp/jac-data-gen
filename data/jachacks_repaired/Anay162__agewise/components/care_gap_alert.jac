"""Warning card for a detected preventive care gap."""

import from components.status_badge { StatusBadge }

import from "lucide-react" { AlertTriangle, Calendar }

glob GAP_LABELS: dict = {
         "MISSED_PCP": "Annual Wellness Visit Overdue",
         "MISSED_DENTAL": "Dental Cleaning Overdue",
         "MISSED_VISION": "Eye Exam Overdue",
         "OVERDUE_SPECIALIST": "Specialist Follow-up Overdue",
         "OVERDUE_SCREENING": "Health Screening Overdue"
     };

def:pub CareGapAlert(props: dict) -> JsxElement {
    gap = props.get("gap", {});
    gap_type = str(gap.get("gap_type", ""));
    urgency = str(gap.get("urgency", "LOW"));
    is_urgent = urgency == "HIGH" or urgency == "CRITICAL";
    title = GAP_LABELS.get(gap_type, gap_type.replace("_", " "));

    outer_cls = f"flex items-start gap-3 p-4 rounded-xl border {'bg-orange-50 border-orange-200'
        if is_urgent
        else 'bg-yellow-50 border-yellow-200'}";
    icon_cls = f"w-5 h-5 mt-0.5 flex-shrink-0 {'text-orange-500'
        if is_urgent
        else 'text-yellow-500'}";

    last_visit_str = gap.get("last_visit_date", "");
    last_visit_display = new(Date, f"{last_visit_str}T00:00:00").toLocaleDateString(
        "en-US", {"month": "long", "day": "numeric", "year": "numeric"}
    )
        if last_visit_str
        else "No visit on record";
    days_overdue = gap.get("days_overdue", 0);
    overdue_txt = f" · {days_overdue} days overdue" if days_overdue > 0 else "";

    return
        <div className={outer_cls}>
            <AlertTriangle className={icon_cls}/>
            <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap mb-1">
                    <span className="font-medium text-warm-900">{title}</span>
                    <StatusBadge status={urgency}/>
                </div>
                <div className="text-sm text-warm-600">
                    {last_visit_display}{overdue_txt}
                </div>
                <div
                    className="flex items-center gap-1 mt-2 text-sm font-medium text-primary-600"
                >
                    <Calendar className="w-4 h-4"/>
                    Schedule with:{" "}
                    {gap.get("specialty_needed", "")}
                </div>
            </div>
        </div>;
}
