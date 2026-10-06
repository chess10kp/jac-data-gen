"""Edge: Patient/Provider → Appointment."""

edge has_appointment {
    has scheduled_at: str = "",
        reminder_sent: bool = False;
}
