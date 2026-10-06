"""TransferFollowup walker — follows up on transfers not completed within 5 business days."""

import from graph.nodes.patient { Patient }
import from graph.nodes.records_transfer { RecordsTransfer }
import from graph.nodes.phone_call { PhoneCall }
import from datetime { datetime, timedelta }
import from uuid { uuid4 }

walker TransferFollowup {
    has stall_days: int = 5,
        followups_queued: int = 0;

    can followup with Patient entry {
        today = datetime.utcnow().date();
        cutoff = (today - timedelta(days=self.stall_days)).isoformat();

        stalled = [
            n for n in [here-->]
            if isinstance(n, RecordsTransfer)
            and n.status in ["CALL_QUEUED", "REQUESTED"]
            and n.requested_date <= cutoff
        ];

        for transfer in stalled {
            call = PhoneCall(
                call_id=str(uuid4()),
                call_type="RECORDS_FOLLOWUP",
                target_name=transfer.sending_provider_name,
                purpose=f"Follow up on records request for {here.name}: {transfer.purpose}",
                status="QUEUED",
                created_at=datetime.utcnow().isoformat()
            );
            root ++> call;
            self.followups_queued += 1;
        }

        report {"patient": here.name, "followups_queued": self.followups_queued};
    }
}
