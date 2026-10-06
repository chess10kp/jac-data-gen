"""AppointmentSync walker — syncs appointments from health portal APIs and email."""

import from graph.nodes.patient { Patient }
import from graph.nodes.appointment { Appointment }
import from datetime { datetime }
import from uuid { uuid4 }

walker AppointmentSync {
    has source: str = "PORTAL",   # PORTAL | EMAIL | MANUAL
        synced_count: int = 0;

    can sync with Patient entry {
        # In production: call health portal API (MyChart, etc.)
        # Here we walk existing appointments and refresh status
        existing = [n for n in [here-->] if isinstance(n, Appointment)];
        for appt in existing {
            if appt.status == "SCHEDULED" and appt.appointment_date < datetime.utcnow().isoformat()[:10] {
                appt.status = "COMPLETED";
                self.synced_count += 1;
            }
        }
        report {"patient": here.name, "appointments_synced": self.synced_count};
    }
}
