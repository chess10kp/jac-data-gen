"""Colored badge for status/severity/classification labels."""

def:pub StatusBadge(props: dict) -> JsxElement {
    status = str(props.get("status", ""));
    extra_class = str(props.get("className", ""));

    presets = {
        "CRITICAL": "bg-red-100 text-red-800",
        "HIGH": "bg-orange-100 text-orange-800",
        "MEDIUM": "bg-yellow-100 text-yellow-700",
        "LOW": "bg-blue-100 text-blue-700",
        "SCHEDULED": "bg-accent-100 text-accent-700",
        "COMPLETED": "bg-warm-200 text-warm-700",
        "CANCELLED": "bg-red-100 text-red-700",
        "OPEN": "bg-orange-100 text-orange-800",
        "IN_PROGRESS": "bg-blue-100 text-blue-800",
        "APPEALED": "bg-purple-100 text-purple-800",
        "RESOLVED": "bg-accent-100 text-accent-700",
        "ELIGIBLE": "bg-accent-100 text-accent-800",
        "INELIGIBLE": "bg-warm-200 text-warm-600",
        "essential": "bg-accent-100 text-accent-700",
        "useful": "bg-blue-100 text-blue-700",
        "wasteful": "bg-orange-100 text-orange-700",
        "suspicious": "bg-red-100 text-red-800"
    };

    colors = presets.get(status, "bg-warm-200 text-warm-700");
    label = status.capitalize().replace("_", " ") if status else "";

    return <span className={f"badge {colors} {extra_class}"}>{label}</span>;
}
