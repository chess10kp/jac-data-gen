"""CareGap node — tracks detected gaps in preventive care.

Created by the CareGapDetector walker when a patient has not had
a required visit within the recommended interval.
"""

node CareGap {
    has gap_id: str = "",
        gap_type: str = "",          # MISSED_PCP | MISSED_DENTAL | MISSED_VISION | OVERDUE_SPECIALIST | OVERDUE_SCREENING
        last_visit_date: str = "",   # ISO date of most recent relevant visit, empty if never
        recommended_interval_days: int = 365,
        days_overdue: int = 0,
        urgency: str = "MEDIUM",     # LOW | MEDIUM | HIGH | CRITICAL
        specialty_needed: str = "",  # e.g. "Dentist", "Ophthalmologist"
        recommended_action: str = "",
        detected_date: str = "",
        acknowledged: bool = False,
        acknowledged_date: str = "",
        resolved: bool = False,
        resolved_date: str = "";
}
