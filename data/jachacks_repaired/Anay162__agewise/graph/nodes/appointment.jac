"""Appointment node — tracks medical appointments for scheduling and reminders."""

node Appointment {
    has appointment_id: str = "",
        appointment_date: str = "",
        appointment_time: str = "",
        provider_name: str = "",
        provider_npi: str = "",
        provider_phone: str = "",
        facility_name: str = "",
        facility_address: str = "",
        specialty: str = "",
        purpose: str = "",
        status: str = "SCHEDULED",  # SCHEDULED | COMPLETED | CANCELLED | NO_SHOW
        reminder_sent: bool = False,
        transportation_needed: bool = False,
        notes: str = "",
        created_at: str = "";
}
