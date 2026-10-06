"""OutcomeRecorder walker — updates Dispute nodes based on call outcomes."""

import from graph.nodes.dispute { Dispute }
import from graph.nodes.phone_call { PhoneCall }

import from datetime { datetime }

walker OutcomeRecorder {

    can record with PhoneCall entry {
        if here.outcome == "PENDING" or here.outcome_summary == "" {
            disengage;
        }

        # Find all disputes linked to this call
        parent_disputes = [d for d in [<--] if isinstance(d, Dispute)];
        for dispute in parent_disputes {
            if here.outcome == "RESOLVED" {
                resolution_amount = 0.0;
                for ref in here.action_items {
                    if "$" in ref {
                        try {
                            amount_str = ref.split("$")[1].split()[0].replace(",", "");
                            resolution_amount = float(amount_str);
                        } except Exception { }
                    }
                }
                dispute.status = "RESOLVED";
                dispute.resolved_date = datetime.utcnow().isoformat();
                dispute.resolution_amount = resolution_amount;
                print(f"[OutcomeRecorder] Dispute {dispute.dispute_id} resolved via call");
            } elif here.outcome == "ESCALATED" {
                dispute.status = "IN_PROGRESS";
                print(f"[OutcomeRecorder] Dispute {dispute.dispute_id} needs escalation");
            }
        }
    }
}
