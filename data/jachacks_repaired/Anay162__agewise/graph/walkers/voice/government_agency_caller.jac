"""GovernmentAgencyCaller walker — voice agent to call SSA, Medicare, Medicaid, VA, etc."""

import from graph.nodes.phone_call { PhoneCall }
import from integrations.voice.bland_client { initiate_bland_call }
import from datetime { datetime }

glob GOVERNMENT_PHONES: dict = {
    "SSA": "1-800-772-1213",
    "MEDICARE": "1-800-633-4227",
    "MEDICAID": "1-877-267-2323",
    "VA": "1-800-827-1000"
};
walker GovernmentAgencyCaller {
    can call with PhoneCall entry {
        if here.call_type != "GOVERNMENT_AGENCY" {
            return;
        }
        phone = here.target_phone or GOVERNMENT_PHONES.get(here.target_name, "");
        result = initiate_bland_call(
            phone_number=phone,
            task=here.purpose,
            call_data={"call_type": "government", "agency": here.target_name}
        );
        here.external_call_id = result.get("call_id", "");
        here.status = "IN_PROGRESS";
        here.initiated_at = datetime.utcnow().isoformat();
        report {"call_initiated": here.external_call_id};
    }
}
