"""Role definitions for AgeWise access control."""

# User roles
glob ROLES: dict = {
    "PATIENT": {
        "description": "The aging parent themselves",
        "can_view_own_data": True,
        "can_view_financial": True,
        "can_initiate_calls": True,
        "can_approve_appeals": True,
        "can_view_legal": True
    },
    "ADULT_CHILD": {
        "description": "Authorized adult child / family caregiver",
        "can_view_own_data": True,
        "can_view_financial": True,
        "can_initiate_calls": True,
        "can_approve_appeals": True,
        "can_view_legal": True,
        "requires_patient_consent": True
    },
    "POA_AGENT": {
        "description": "Holds legal power of attorney",
        "can_view_own_data": True,
        "can_view_financial": True,
        "can_initiate_calls": True,
        "can_approve_appeals": True,
        "can_view_legal": True,
        "can_sign_documents": True,
        "requires_poa_verification": True
    },
    "CARE_MANAGER": {
        "description": "Professional care manager (read-only + notifications)",
        "can_view_own_data": True,
        "can_view_financial": False,
        "can_initiate_calls": False,
        "can_approve_appeals": False,
        "can_view_legal": False
    },
    "ADMIN": {
        "description": "AgeWise platform administrator",
        "all_permissions": True
    }
};
# Role hierarchy (higher index = more permissions)
glob ROLE_HIERARCHY: list[str] = [
    "CARE_MANAGER",
    "PATIENT",
    "ADULT_CHILD",
    "POA_AGENT",
    "ADMIN"
];
