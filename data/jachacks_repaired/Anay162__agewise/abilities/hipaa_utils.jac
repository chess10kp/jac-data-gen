"""HIPAA compliance utilities — PHI detection, de-identification, and safe logging."""

import from re { sub, findall, IGNORECASE }

# Regex patterns for PHI detection
glob PHI_PATTERNS: dict = {
    "ssn": r'\b\d{3}-\d{2}-\d{4}\b',
    "medicare_id": r'\b[1-9][A-Z]{1}[A-Z0-9]{1}[0-9]{2}[A-Z]{1}[A-Z0-9]{1}[0-9]{2}[A-Z]{1}\b',
    "phone": r'\b(\+1[-.]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b',
    "date_of_birth": r'\b(DOB|date of birth|born)\s*[:.]?\s*\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b',
    "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    "credit_card": r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',
    "bank_account": r'\b(account|acct)\s*#?\s*\d{8,17}\b'
};
"""
Scan text for PHI patterns and return list of detected PHI types.
Does NOT return the actual PHI values.
"""
def detect_phi(text: str) -> list[str] {
    detected = [];
    for (phi_type, pattern) in PHI_PATTERNS.items() {
        if findall(pattern, text, IGNORECASE) {
            detected.append(phi_type);
        }
    }
    return detected;
}

"""Replace PHI patterns in text with [REDACTED] markers for safe logging."""
def redact_phi(text: str) -> str {
    result = text;
    for (phi_type, pattern) in PHI_PATTERNS.items() {
        result = sub(pattern, f"[{phi_type.upper()}_REDACTED]", result, flags=IGNORECASE);
    }
    return result;
}

"""Return a PHI-redacted version of a log message."""
def safe_log(message: str, level: str = "INFO") -> str {
    redacted = redact_phi(message);
    return f"[{level}] {redacted}";
}

"""
Filter data fields to the minimum necessary for a stated purpose.
Per HIPAA minimum necessary standard (45 CFR §164.502(b)).
"""
def check_minimum_necessary_access(data_fields: list[str], purpose: str) -> list[str] {
    purpose_allowances = {
        "billing": ["name", "dob", "insurance_id", "diagnosis_codes", "service_dates"],
        "treatment": ["name", "dob", "medications", "allergies", "diagnosis", "labs"],
        "operations": ["name", "contact_info", "appointment_dates"],
        "notification": ["name", "phone", "email"],
        "audit": ["patient_id", "service_dates", "provider_id", "claim_numbers"]
    };
    allowed = purpose_allowances.get(purpose, []);
    return [f for f in data_fields if f in allowed];
}
