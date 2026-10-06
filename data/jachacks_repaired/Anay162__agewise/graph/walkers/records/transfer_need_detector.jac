"""TransferNeedDetector walker — detects when records from another provider are needed."""

import from graph.nodes.patient { Patient }
import from graph.nodes.appointment { Appointment }
import from graph.nodes.records_transfer { RecordsTransfer }
import from abilities.llm_abilities { assess_records_transfer_need }
import from datetime { datetime, timedelta }
import from uuid { uuid4 }

walker TransferNeedDetector {
    has transfers_needed: int = 0;

    can detect with Patient entry {
        today = datetime.utcnow().date();
        lookahead = (today + timedelta(days=14)).isoformat();

        upcoming = [
            n for n in [here-->]
            if isinstance(n, Appointment)
            and n.status == "SCHEDULED"
            and n.appointment_date <= lookahead
        ];

        existing_transfers = [n for n in [here-->] if isinstance(n, RecordsTransfer)];
        existing_purposes = {t.purpose for t in existing_transfers};

        for appt in upcoming {
            result = assess_records_transfer_need(
                specialty=appt.specialty,
                purpose=appt.purpose,
                existing_transfers=list(existing_purposes)
            );
            if result.get("transfer_needed") {
                transfer = RecordsTransfer(
                    transfer_id=str(uuid4()),
                    purpose=f"Records for {appt.specialty} appointment on {appt.appointment_date}",
                    status="PENDING",
                    requested_date=datetime.utcnow().isoformat()[:10]
                );
                here ++> transfer;
                self.transfers_needed += 1;
            }
        }

        report {"patient": here.name, "transfers_needed": self.transfers_needed};
    }
}
