"""Explanation of Benefits (EOB) type definitions and field descriptors."""

# EOB section types
glob EOB_SECTIONS: list[str] = [
    "HEADER",
    "PATIENT_INFO",
    "PROVIDER_INFO",
    "SERVICE_LINES",
    "TOTALS",
    "NOTES",
    "APPEALS_NOTICE"
];

# Standard EOB field names mapped to display labels
glob EOB_FIELD_LABELS: dict = {
    "claim_number": "Claim Number",
    "service_date": "Date of Service",
    "provider_name": "Provider Name",
    "provider_npi": "Provider NPI",
    "billed_amount": "Amount Billed",
    "allowed_amount": "Medicare Approved Amount",
    "paid_amount": "Medicare Paid",
    "patient_responsibility": "Your Responsibility",
    "deductible_applied": "Deductible Applied",
    "coinsurance": "Coinsurance (20%)",
    "copay": "Copay",
    "adjustment_reason": "Adjustment Reason",
    "remark_code": "Remark Code",
    "denial_reason": "Denial Reason"
};
# Medicare Summary Notice (MSN) message codes → plain English
glob MSN_MESSAGES: dict = {
    "MSN01": "Medicare paid for this service.",
    "MSN02": "You may be billed for the deductible amount.",
    "MSN03": "You may be billed for the coinsurance amount.",
    "MSN10": "This service is covered only when medically necessary.",
    "MSN15": "This claim was denied. See explanation below.",
    "MSN18": "This service is not covered by Medicare.",
    "MSN22": "You have the right to appeal this decision.",
    "MSN29": "The time limit for filing has expired.",
    "MSN45": "The charge exceeds the Medicare-approved amount.",
    "MSN96": "This is a non-covered service.",
    "MSN109": "This claim is not covered by this Medicare contractor."
};