"""Legal document type definitions."""

# Supported legal document types
glob LEGAL_DOC_TYPES: list[str] = [
    "POWER_OF_ATTORNEY",
    "HEALTHCARE_PROXY",
    "LIVING_WILL",
    "ADVANCE_DIRECTIVE",
    "DURABLE_POA_FINANCIAL",
    "TRUST",
    "WILL",
    "HIPAA_AUTHORIZATION",
    "DO_NOT_RESUSCITATE",
    "POLST",
    "GUARDIANSHIP_ORDER",
    "CONSERVATORSHIP_ORDER"
];

# Document status transitions
glob LEGAL_DOC_STATUS: list[str] = [
    "ACTIVE",
    "EXPIRED",
    "REVOKED",
    "SUPERSEDED",
    "PENDING_NOTARIZATION",
    "DRAFT"
];

# Renewal warning thresholds by document type (days before expiry)
glob RENEWAL_WARN_DAYS: dict = {
    "POWER_OF_ATTORNEY": 90,
    "HEALTHCARE_PROXY": 90,
    "HIPAA_AUTHORIZATION": 60,
    "TRUST": 365,
    "WILL": 365,
    "ADVANCE_DIRECTIVE": 180,
    "LIVING_WILL": 180,
    "DURABLE_POA_FINANCIAL": 90
};
# Jurisdictions with specific POA requirements
glob STRICT_POA_STATES: list[str] = [
    "CA", "FL", "NY", "TX", "PA", "OH", "IL", "GA", "MI"
];

# Common beneficiary relationship types
glob BENEFICIARY_RELATIONSHIPS: list[str] = [
    "SPOUSE",
    "CHILD",
    "GRANDCHILD",
    "SIBLING",
    "PARENT",
    "NIECE_NEPHEW",
    "FRIEND",
    "TRUST",
    "CHARITY",
    "ESTATE"
];
