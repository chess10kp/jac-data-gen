"""Table row for a single medication with refill progress bar."""

import from "lucide-react" { AlertTriangle }

def RefillBar(props: dict) -> JsxElement {
    days_left = int(props.get("daysLeft", 0) or 0);
    pct = max(0.0, min(100.0, (days_left / 30.0) * 100.0));
    color = "bg-red-500"
        if days_left < 0
        else ("bg-yellow-400" if days_left <= 7 else "bg-accent-500");
    label = f"Overdue by {abs(days_left)} days"
        if days_left < 0
        else ("Due today" if days_left == 0 else f"{days_left} days left");
    lbl_cls = "text-red-600 font-medium"
        if days_left < 0
        else ("text-yellow-700 font-medium" if days_left <= 7 else "text-warm-600");

    return
        <div className="min-w-[120px]">
            <div className="flex justify-between text-xs text-warm-500 mb-1">
                <span>Refill</span>
                <span className={lbl_cls}>{label}</span>
            </div>
            <div className="h-2 bg-warm-200 rounded-full overflow-hidden">
                <div
                    className={f"h-full rounded-full transition-all {color}"}
                    style={{"width": f"{pct:.0f}%"}}
                />
            </div>
        </div>;
}

def:pub MedicationRow(props: dict) -> JsxElement {
    med = props.get("med", {});
    has_interaction = props.get("hasInteraction", False);
    row_cls = f"border-b border-warm-100 hover:bg-warm-50 transition-colors {'bg-orange-50/50'
        if has_interaction
        else ''}";

    return
        <tr className={row_cls}>
            <td className="py-4 px-4">
                <div className="flex items-center gap-2">
                    <div>
                        <div className="font-medium text-warm-900">
                            {med.get("drug_name", "")}
                        </div>
                        <div className="text-sm text-warm-500">
                            {med.get("generic_name", "")} · {med.get("strength", "")}
                        </div>
                    </div>
                    {<span title="Drug interaction flagged">
                        <AlertTriangle
                            className="w-4 h-4 text-orange-500 flex-shrink-0"
                        />
                    </span>
                        if has_interaction
                        else <span></span>}
                </div>
            </td>
            <td className="py-4 px-4 text-sm text-warm-600">
                {med.get("therapeutic_class", "")}
            </td>
            <td className="py-4 px-4 text-sm text-warm-600">
                {med.get("prescribing_provider", "")}
            </td>
            <td className="py-4 px-4 text-sm text-warm-600">
                {med.get("pharmacy_name", "")}
            </td>
            <td className="py-4 px-4 text-sm text-warm-500">
                {med.get("refills_remaining", 0)} left
            </td>
            <td className="py-4 px-4">
                <RefillBar daysLeft={med.get("days_until_refill", 0)}/>
            </td>
        </tr>;
}
