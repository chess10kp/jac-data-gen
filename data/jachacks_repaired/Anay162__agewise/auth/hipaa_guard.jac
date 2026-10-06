"""HIPAA compliance guards for PHI access and audit logging."""

import from datetime { datetime }
import from os { environ }

# PHI field names that require audit logging on access
glob PHI_FIELDS: list[str] = [
    "name", "dob", "medicare_id", "medicaid_id", "ssn",
    "address", "phone", "email", "diagnosis_codes", "icd_codes",
    "cpt_codes", "raw_content", "extracted_text", "letter_content",
    "account_number", "routing_number", "plaid_access_token"
];

# Audit log storage (in production, write to secure append-only store)
glob _audit_log: list[dict] = [];

"""Log PHI access for HIPAA compliance audit trail."""
def audit_phi_access(user_id: str, patient_id: str, action: str, fields: list[str]) -> None {
    `entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "user_id": user_id,
        "patient_id": patient_id,
        "action": action,
        "fields_accessed": fields,
        "environment": environ.get("APP_ENV", "development")
    };
    _audit_log.append(`entry);
    if environ.get("APP_ENV") != "development" {
        print(f"[HIPAA_AUDIT] {action} on patient {patient_id} by {user_id}: {fields}");
    }
}

"""Mask PHI values for logging and display."""
def mask_phi(value: str, field_name: str) -> str {
    if field_name in ["ssn"] {
        return f"***-**-{value[-4:]}" if len(value) >= 4 else "***";
    }
    if field_name in ["medicare_id", "medicaid_id"] {
        return f"****{value[-4:]}" if len(value) >= 4 else "****";
    }
    if field_name in ["account_number", "routing_number"] {
        return f"****{value[-4:]}" if len(value) >= 4 else "****";
    }
    if field_name == "dob" {
        # Show only year
        return value[:4] + "-**-**" if len(value) >= 4 else "****-**-**";
    }
    return value;
}

"""Retrieve audit log entries, optionally filtered by patient."""
def get_audit_log(patient_id: str = "") -> list[dict] {
    if patient_id == "" {
        return _audit_log;
    }
    return [e for e in _audit_log if e["patient_id"] == patient_id];
}

"""Filter requested fields to minimum necessary for stated purpose."""
def check_minimum_necessary(fields_requested: list[str], purpose: str) -> list[str] {
    purpose_field_map = {
        "billing_audit": ["name", "medicare_id", "dob"],
        "appeal": ["name", "medicare_id", "dob", "diagnosis_codes", "cpt_codes"],
        "notification": ["name", "phone", "email"],
        "financial_review": ["name", "account_number"],
        "full_record": PHI_FIELDS
    };
    allowed = purpose_field_map.get(purpose, []);
    return [f for f in fields_requested if f in allowed];
}
