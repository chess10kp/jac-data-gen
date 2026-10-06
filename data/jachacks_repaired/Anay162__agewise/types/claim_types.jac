"""Claim-related type definitions."""

# CMS-1500 (professional) claim type indicators
glob CLAIM_TYPE_PROFESSIONAL: str = "CMS-1500";
glob CLAIM_TYPE_INSTITUTIONAL: str = "UB-04";
glob CLAIM_TYPE_DENTAL: str = "ADA-2019";
glob CLAIM_TYPE_PHARMACY: str = "NCPDP";

# Claim frequency types (3rd digit of type of bill)
glob CLAIM_FREQUENCY: dict = {
    "1": "Admit through Discharge Claim",
    "2": "Interim - First Claim",
    "3": "Interim - Continuing Claim",
    "4": "Interim - Last Claim",
    "5": "Late Charge Only",
    "6": "Adjustment of Prior Claim",
    "7": "Replacement of Prior Claim",
    "8": "Void/Cancel of Prior Claim"
};
# Claim adjustment reason codes (CARCs) — top 20
glob CARC_CODES: dict = {
    "1": "Deductible Amount",
    "2": "Coinsurance Amount",
    "3": "Co-payment Amount",
    "4": "The procedure code is inconsistent with the modifier used",
    "5": "The procedure code/bill type is inconsistent with the place of service",
    "6": "The procedure/revenue code is inconsistent with the patient's age",
    "7": "The procedure/revenue code is inconsistent with the patient's gender",
    "9": "The diagnosis is inconsistent with the patient's age",
    "10": "The diagnosis is inconsistent with the patient's gender",
    "11": "The diagnosis is inconsistent with the procedure",
    "16": "Claim/service lacks information or has submission/billing error(s)",
    "18": "Exact duplicate claim/service",
    "22": "This care may be covered by another payer",
    "29": "The time limit for filing has expired",
    "45": "Charge exceeds fee schedule/maximum allowable or contracted/legislated fee arrangement",
    "96": "Non-covered charge(s)",
    "97": "The benefit for this service is included in the payment/allowance for another service",
    "109": "Claim/service not covered by this payer/contractor",
    "119": "Benefit maximum for this time period or occurrence has been reached",
    "151": "Payment adjusted because the payer deems the information submitted does not support this many/frequency of services"
};
# Remittance advice remark codes (RARCs) — key ones
glob RARC_CODES: dict = {
    "M15": "Separately billed services/tests have been bundled",
    "M76": "Missing/incomplete/invalid diagnosis or condition",
    "M77": "Missing/incomplete/invalid place of service",
    "M79": "Missing/incomplete/invalid charge",
    "M86": "Service denied because payment already made for same/similar procedure",
    "N30": "Patient not eligible for the requested service",
    "N115": "This decision was based on a Local Coverage Determination (LCD)",
    "N130": "Consult plan benefit documents/guidelines for information about restrictions for this service",
    "N522": "Duplicate of a claim processed, or to be processed, as a crossover claim"
};