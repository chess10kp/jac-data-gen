"""PriorAuthFollowup walker — follows up on stalled prior authorization requests."""

import from graph.nodes.patient { Patient }
import from graph.nodes.prior_auth { PriorAuth }
import from graph.nodes.phone_call { PhoneCall }
import from datetime { datetime, timedelta }
import from uuid { uuid4 }

walker PriorAuthFollowup {
    has stall_days: int = 5,
        followups_queued: int = 0;

    can followup with Patient entry {
        today = datetime.utcnow().date();
        cutoff = (today - timedelta(days=self.stall_days)).isoformat();

        for med in [here-->] {
            for rx in [med-->] {
                for pa in [rx-->] {
                    if not isinstance(pa, PriorAuth) {
                        continue;
                    }
                    if pa.status != "PENDING" {
                        continue;
                    }
                    if pa.requested_date and pa.requested_date <= cutoff {
                        call = PhoneCall(
                            call_id=str(uuid4()),
                            call_type="PRIOR_AUTH_FOLLOWUP",
                            purpose=f"Follow up on prior auth {pa.auth_number} for {here.name}",
                            status="QUEUED",
                            created_at=datetime.utcnow().isoformat()
                        );
                        root ++> call;
                        self.followups_queued += 1;
                    }
                }
            }
        }

        report {"patient": here.name, "followups_queued": self.followups_queued};
    }
}
