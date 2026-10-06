def:pub toneClass(tone: str) -> str {
    return (
        "gw-summary-card gw-glass-panel is-frost"
            if tone == "frost"
            else "gw-summary-card gw-glass-panel is-cyan"
                if tone == "cyan"
                else "gw-summary-card gw-glass-panel is-aqua"
                    if tone == "aqua"
                    else "gw-summary-card gw-glass-panel is-amber"
    );
}

def:pub severityClass(severity: str) -> str {
    return (
        "gw-severity-pill gw-severity-critical"
            if severity == "critical"
            else "gw-severity-pill gw-severity-high"
                if severity == "high"
                else "gw-severity-pill gw-severity-medium"
    );
}

def:pub walkerStateClass(state: str) -> str {
    return (
        "gw-state-pill gw-state-active"
            if state == "Active"
            else "gw-state-pill gw-state-queued"
                if state == "Queued"
                else "gw-state-pill gw-state-watching"
    );
}
