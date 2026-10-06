"""TransferInitiator walker — dispatches voice agent to request medical records."""

import from graph.nodes.patient { Patient }
import from graph.nodes.records_transfer { RecordsTransfer }
import from graph.nodes.phone_call { PhoneCall }
import from datetime { datetime }
import from uuid { uuid4 }

walker TransferInitiator {
    has calls_queued: int = 0;

    can initiate with Patient entry {
        ready = [
            n for n in [here-->]
            if isinstance(n, RecordsTransfer)
            and n.status == "PENDING"
            and n.hipaa_auth_generated
        ];

        for transfer in ready {
            call = PhoneCall(
                call_id=str(uuid4()),
                call_type="RECORDS_REQUEST",
                target_name=transfer.sending_provider_name,
                target_phone=transfer.sending_provider_phone,
                purpose=f"Request medical records for {here.name}: {transfer.purpose}",
                status="QUEUED",
                created_at=datetime.utcnow().isoformat()
            );
            root ++> call;
            transfer.status = "CALL_QUEUED";
            self.calls_queued += 1;
        }

        report {"patient": here.name, "calls_queued": self.calls_queued};
    }
}
