"""CallDispatcher walker — queues and prioritizes voice agent calls.

Walks all open Dispute nodes, determines which ones need a phone call
(vs. written appeal), builds call scripts, and dispatches to Bland.ai
via the call_executor walker.
"""

import from graph.nodes.claim { Claim }
import from graph.nodes.insurer { Insurer }
import from graph.nodes.patient { Patient }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from graph.nodes.phone_call { PhoneCall }
import from integrations.voice.call_script_builder { build_dispute_call_script }
import from integrations.voice.bland_client { initiate_call }

import from datetime { datetime }
import from uuid { uuid4 }

# Dispute types that benefit from a phone call vs. written appeal only
glob PHONE_RESOLVABLE = [
    "BILL_EOB_MISMATCH",
    "FEE_SCHEDULE_OVERAGE",
    "DUPLICATE_CHARGE",
    "CLAIM_STATUS"
];

walker CallDispatcher {
    has current_claim_number: str = "";
    has current_insurer: str = "";
    has current_insurer_phone: str = "";

    has patient_name: str = "",
        patient_medicare_id: str = "",
        dry_run: bool = True;   # True = build scripts but don't call

    can start with Patient entry {
        self.patient_name = here.name;
        self.patient_medicare_id = here.medicare_id;
        visit [-->];
    }

    can check_claim_disputes with Claim entry {
        self.current_claim_number = here.claim_number;
        self.current_insurer = "";
        # Get insurer info from claim → insurer edge
        insurers = [i for i in [here-->] if isinstance(i, Insurer)];
        if len(insurers) > 0 {
            self.current_insurer = insurers[0].name;
            self.current_insurer_phone = insurers[0].claims_phone;
        }
        visit [-->];
    }

    can dispatch_call with Dispute entry {
        if here.error_type not in PHONE_RESOLVABLE {
            disengage;
        }
        if here.status not in ["OPEN", "IN_PROGRESS"] {
            disengage;
        }

        # Check if there's already a pending call
        existing_calls = [c for c in [here-->] if isinstance(c, PhoneCall) and c.outcome == "PENDING"];
        if len(existing_calls) > 0 {
            disengage;
        }

        script = build_dispute_call_script(
            dispute_description=here.description,
            error_type=here.error_type,
            claim_number=getattr(self, "current_claim_number", ""),
            cpt_code="",
            denial_reason="\n".join(here.citations),
            insurer_name=getattr(self, "current_insurer", "the insurer"),
            insurer_phone=getattr(self, "current_insurer_phone", ""),
            patient_name=self.patient_name,
            patient_medicare_id=self.patient_medicare_id
        );

        call = PhoneCall(
            call_id=str(uuid4()),
            call_type="BILLING_DISPUTE",
            provider_api="bland",
            initiated_at=datetime.utcnow().isoformat(),
            to_phone=script.get("to_phone", ""),
            to_name=getattr(self, "current_insurer", "Insurer"),
            outcome="PENDING",
            created_at=datetime.utcnow().isoformat()
        );

        if not self.dry_run and script.get("to_phone", "") != "" {
            try {
                result = initiate_call(
                    phone_number=script["to_phone"],
                    call_script=script,
                    metadata={"dispute_id": here.dispute_id, "patient": self.patient_name}
                );
                call.call_id = result.get("call_id", call.call_id);
                call.outcome = "PENDING";
                print(f"[CallDispatcher] Call initiated: {call.call_id}");
            } except Exception as e {
                call.outcome = "FAILED";
                print(f"[CallDispatcher] Call failed: {e}");
            }
        } else {
            print(f"[CallDispatcher] DRY RUN — would call {script.get('to_phone', 'unknown')} for dispute {here.dispute_id}");
        }

        here ++> call;
        here.status = "IN_PROGRESS";
    }
}
