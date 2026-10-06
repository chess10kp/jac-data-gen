import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from graph.nodes.appointment { Appointment }
import from abilities.llm_abilities { parse_appointment_email }

import from datetime { datetime }
import from uuid { uuid4 }


"""Walks Patient -> Documents, parses appointment confirmations."""
walker AppointmentEmailParser {

    has parsed: int = 0,
        skipped: int = 0,
        patient_ref: Patient = Patient(name="");

    can start with Patient entry {
        self.patient_ref = here;
        visit [-->];
    }

    can check_doc with Document entry {
        # Only process likely appointment-related documents
        classification = here.classification.upper();
        relevant_types = {"APPOINTMENT_CONFIRMATION", "EMAIL", "UNKNOWN"};
        if classification not in relevant_types and "APPOINTMENT" not in classification {
            disengage;
        }

        raw = here.raw_content if here.raw_content else here.plain_english_summary;
        if not raw {
            disengage;
        }

        email_subject: str = "";
        email_sender: str = "";
        result = parse_appointment_email(
            email_subject=email_subject,
            email_body=raw[:4000],
            sender=email_sender
        );

        if not result or not result.get("is_appointment_related", True) {
            self.skipped += 1;
            disengage;
        }

        appt_date = result.get("appointment_date", "");
        provider = result.get("provider_name", "");
        if not appt_date or not provider {
            self.skipped += 1;
            disengage;
        }

        # Check for duplicate (same provider + date)
        existing = [
            n for n in [self.patient_ref-->]
            if isinstance(n, Appointment)
            and n.appointment_date == appt_date
            and n.provider_name == provider
        ];
        if existing {
            self.skipped += 1;
            disengage;
        }

        appt = Appointment(
            appointment_id=str(uuid4()),
            appointment_date=appt_date,
            appointment_time=result.get("appointment_time", ""),
            provider_name=provider,
            facility_name=result.get("facility_name", ""),
            facility_address=result.get("facility_address", ""),
            specialty=result.get("specialty", ""),
            purpose=result.get("visit_purpose", ""),
            status="SCHEDULED",
            reminder_sent=False,
            notes=result.get("prep_instructions", ""),
            created_at=str(datetime.utcnow())
        );
        self.patient_ref ++> appt;
        self.parsed += 1;
        print(f"[AppointmentEmailParser] Parsed: {provider} on {appt_date}");
    }

    can finish with Patient entry {
        report {"parsed": self.parsed, "skipped": self.skipped};
    }
}
