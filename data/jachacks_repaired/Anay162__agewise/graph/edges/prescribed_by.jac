"""prescribed_by edge — Prescription written by a Provider."""

edge prescribed_by {
    has encounter_date: str = "",
        encounter_type: str = "";   # OFFICE_VISIT | TELEHEALTH | HOSPITAL
}
