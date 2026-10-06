"""Medicare appeals process type definitions."""

# Appeal level configurations
glob APPEAL_LEVELS: dict = {
    1: {
        "name": "Redetermination",
        "entity": "Medicare Administrative Contractor (MAC)",
        "deadline_days": 120,
        "form": "CMS-20027",
        "address_type": "MAC",
        "decision_days": 60
    },
    2: {
        "name": "Reconsideration",
        "entity": "Qualified Independent Contractor (QIC)",
        "deadline_days": 180,
        "form": "CMS-20033",
        "address_type": "QIC",
        "decision_days": 60
    },
    3: {
        "name": "ALJ Hearing",
        "entity": "Office of Medicare Hearings and Appeals (OMHA)",
        "deadline_days": 60,
        "form": "OMHA-100",
        "address_type": "OMHA",
        "decision_days": 90,
        "minimum_amount": 180.0
    },
    4: {
        "name": "Medicare Appeals Council",
        "entity": "Departmental Appeals Board (DAB)",
        "deadline_days": 60,
        "form": "DAB-101",
        "address_type": "DAB",
        "decision_days": 90
    },
    5: {
        "name": "Federal District Court",
        "entity": "U.S. District Court",
        "deadline_days": 60,
        "form": "CIVIL_COMPLAINT",
        "address_type": "COURT",
        "decision_days": 365,
        "minimum_amount": 1760.0
    }
};
# Appeal letter sections
glob APPEAL_LETTER_SECTIONS: list[str] = [
    "HEADER",
    "PATIENT_IDENTIFICATION",
    "CLAIM_IDENTIFICATION",
    "STATEMENT_OF_FACTS",
    "LEGAL_BASIS",
    "MEDICAL_NECESSITY_ARGUMENT",
    "CODING_ARGUMENT",
    "SUPPORTING_EVIDENCE",
    "RELIEF_REQUESTED",
    "SIGNATURE"
];

# Common appeal arguments by error type
glob APPEAL_ARGUMENTS: dict = {
    "DUPLICATE_CLAIM": "The services billed on these claims were rendered on separate dates and constitute distinct episodes of care.",
    "UPCODING": "The documentation supports the level of service billed per CMS E/M guidelines.",
    "UNBUNDLING": "These procedures are not subject to NCCI bundling rules due to separate patient encounters.",
    "WRONG_MODIFIER": "The modifier usage is appropriate and supported by the clinical documentation.",
    "EXCEEDS_MUE": "The units billed are medically necessary as documented in the patient's clinical record.",
    "NOT_COVERED": "This service is medically necessary and covered under Medicare benefit category 42 CFR §410.",
    "CODING_ERROR": "The correct and most specific ICD-10-CM code has been selected per the Official Guidelines.",
    "PRIOR_AUTH_MISSING": "Prior authorization was obtained and documentation is enclosed.",
    "TIMELY_FILING": "The delay in filing was due to circumstances beyond the provider's control."
};