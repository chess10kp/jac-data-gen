"""AppointmentReschedule walker — dispatches voice agent to reschedule appointments."""

import from graph.nodes.patient { Patient }
import from graph.nodes.appointment { Appointment }
import from graph.nodes.phone_call { PhoneCall }
import from datetime { datetime }
import from uuid { uuid4 }

walker AppointmentReschedule {
    has reason: str = "PATIENT_REQUEST",
        rescheduled_count: int = 0;

    can reschedule with Patient entry {
        to_reschedule = [
            n for n in [here-->]
            if isinstance(n, Appointment) and n.status == "NEEDS_RESCHEDULE"
        ];

        for appt in to_reschedule {
            call = PhoneCall(
                call_id=str(uuid4()),
                call_type="APPOINTMENT_RESCHEDULE",
                target_name=appt.provider_name,
                target_phone=appt.provider_phone if hasattr(appt, "provider_phone") else "",
                purpose=f"Reschedule appointment for {here.name} originally on {appt.appointment_date}",
                status="QUEUED",
                created_at=datetime.utcnow().isoformat()
            );
            root ++> call;
            appt.status = "RESCHEDULE_QUEUED";
            self.rescheduled_count += 1;
        }

        report {"queued_reschedules": self.rescheduled_count};
    }
}
