"""CallExecutor walker — executes a queued voice call via Bland.ai.

Walks PhoneCall nodes with outcome == 'PENDING' and initiates the call
if it hasn't been started yet. Used by the voice_pipeline.
"""

import from graph.nodes.phone_call { PhoneCall }
import from integrations.voice.bland_client { initiate_call, get_call_status }

import from datetime { datetime }

walker CallExecutor {
    has dry_run: bool = True;

    can execute with PhoneCall entry {
        if here.outcome != "PENDING" {
            disengage;
        }
        if here.to_phone == "" {
            here.outcome = "FAILED";
            disengage;
        }
        if not self.dry_run {
            try {
                result = initiate_call(
                    phone_number=here.to_phone,
                    call_script={"main_ask": f"Following up on a dispute for patient."},
                    metadata={"call_id_internal": here.call_id}
                );
                here.call_id = result.get("call_id", here.call_id);
                here.initiated_at = datetime.utcnow().isoformat();
                print(f"[CallExecutor] Call started: {here.call_id} → {here.to_name}");
            } except Exception as e {
                here.outcome = "FAILED";
                print(f"[CallExecutor] Error initiating call: {e}");
            }
        } else {
            print(f"[CallExecutor] DRY RUN — would call {here.to_phone} ({here.to_name})");
        }
    }
}
