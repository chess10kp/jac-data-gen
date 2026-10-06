"""PharmacyCaller walker — voice agent for pharmacy prescription status and refills."""

import from graph.nodes.phone_call { PhoneCall }
import from integrations.voice.bland_client { initiate_bland_call }
import from datetime { datetime }

walker PharmacyCaller {
    can call with PhoneCall entry {
        if here.call_type != "PHARMACY_INQUIRY" {
            return;
        }
        result = initiate_bland_call(
            phone_number=here.target_phone,
            task=here.purpose,
            call_data={"call_type": "pharmacy"}
        );
        here.external_call_id = result.get("call_id", "");
        here.status = "IN_PROGRESS";
        here.initiated_at = datetime.utcnow().isoformat();
        report {"call_initiated": here.external_call_id};
    }
}
