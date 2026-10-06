"""CallScriptBuilder — builds dynamic call scripts from dispute context via by llm()."""

import from abilities.llm_abilities { build_call_script }

"""Build a complete call script for disputing a billing error."""
def build_dispute_call_script(
    dispute_description: str,
    error_type: str,
    claim_number: str,
    cpt_code: str,
    denial_reason: str,
    insurer_name: str,
    insurer_phone: str,
    patient_name: str,
    patient_medicare_id: str,
    prior_calls: list[str] = []
) -> dict {
    script = build_call_script(
        call_type="BILLING_DISPUTE",
        dispute_description=dispute_description,
        claim_number=claim_number,
        cpt_code=cpt_code,
        denial_reason=denial_reason,
        insurer_name=insurer_name,
        patient_name=patient_name,
        patient_medicare_id=patient_medicare_id,
        prior_call_outcomes=prior_calls
    );
    script["to_phone"] = insurer_phone;
    script["call_type"] = "BILLING_DISPUTE";
    return script;
}

"""Build a call script to check on a claim status."""
def build_claim_status_script(
    claim_number: str,
    insurer_name: str,
    insurer_phone: str,
    patient_name: str,
    patient_medicare_id: str
) -> dict {
    return {
        "call_type": "CLAIM_STATUS",
        "to_phone": insurer_phone,
        "opening": (
            f"Hello, I am calling as the authorized representative for {patient_name}, "
            f"Medicare ID {patient_medicare_id}. I am calling to check on the status "
            f"of claim number {claim_number}."
        ),
        "main_ask": (
            f"Can you please tell me the current status of claim {claim_number}? "
            f"Has it been processed? If denied, what is the reason code and what are "
            f"the appeal options?"
        ),
        "escalation_triggers": [
            "If the representative cannot find the claim",
            "If the claim has been denied without a clear reason"
        ],
        "fallback_positions": [
            "Request the claim to be resubmitted",
            "Ask for a supervisor"
        ],
        "closing": (
            "Please provide a reference number for this call. "
            "What is the expected resolution timeframe?"
        )
    };
}
