"""Type definitions for prescriptions and prior authorizations."""

enum MedicationForm {
    TABLET,
    CAPSULE,
    LIQUID,
    PATCH,
    INJECTION,
    INHALER,
    CREAM,
    DROPS,
    SUPPOSITORY
}

enum PriorAuthStatus {
    PENDING,
    UNDER_REVIEW,
    APPROVED,
    DENIED,
    APPEALED,
    EXPIRED
}

enum RefillStatus {
    CURRENT,
    DUE_SOON,
    OVERDUE,
    NO_REFILLS_REMAINING,
    DISCONTINUED
}

enum InteractionSeverity {
    MINIMAL,
    MINOR,
    MODERATE,
    MAJOR,
    CONTRAINDICATED
}

obj DrugInteraction {
    has drug_a: str,
        drug_b: str,
        severity: str,
        description: str,
        clinical_management: str = "";
}
