"""Edge: Patient → Prescription."""

edge has_prescription {
    has prescribed_at: str = "",
        is_current: bool = True;
}
