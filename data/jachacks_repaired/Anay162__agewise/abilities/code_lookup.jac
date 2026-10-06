"""Medical code lookup utilities (local fast lookups without DB)."""

import from types.medical_codes { POS_CODES, MODIFIER_DESC }

"""Return the description for a place-of-service code."""
def describe_pos(pos_code: str) -> str {
    return POS_CODES.get(pos_code.strip(), f"Unknown POS: {pos_code}");
}

"""Return the description for a CPT modifier."""
def describe_modifier(modifier: str) -> str {
    return MODIFIER_DESC.get(modifier.strip().upper(), f"Modifier {modifier} — see CMS guidelines");
}

"""
Quick format validation for ICD-10-CM codes.
Valid format: 1 letter + 2 digits + optional decimal + 1-4 chars.
"""
def is_valid_icd10_format(code: str) -> bool {
    import from re { `match }
    return bool(`match(r'^[A-Z]\d{2}(\.[\w]{1,4})?$', code.strip().upper()));
}

"""
Validate CPT code format (5 digits or 4 digits + letter for Category II/III).
"""
def is_valid_cpt_format(code: str) -> bool {
    import from re { `match }
    return bool(`match(r'^\d{4}[0-9A-Z]$', code.strip().upper()));
}

"""
Validate NPI using Luhn algorithm check digit.
NPI is 10 digits with specific check digit logic.
"""
def is_valid_npi(npi: str) -> bool {
    cleaned = npi.strip().replace("-", "");
    if not cleaned.isdigit() or len(cleaned) != 10 {
        return False;
    }
    # Luhn algorithm for NPI (prefix: 80840 + 10-digit NPI)
    full = "80840" + cleaned;
    total = 0;
    for (i, digit) in enumerate(reversed(full)) {
        n = int(digit);
        if i % 2 == 1 {
            n *= 2;
            if n > 9 {
                n -= 9;
            }
        }
        total += n;
    }
    return total % 10 == 0;
}

"""Determine CPT code category from the code range."""
def get_cpt_category(cpt_code: str) -> str {
    try {
        code_int = int(cpt_code[:5]);
        if 99202 <= code_int <= 99499 {
            return "Evaluation and Management";
        } elif 10004 <= code_int <= 69990 {
            return "Surgery";
        } elif 70010 <= code_int <= 79999 {
            return "Radiology";
        } elif 80047 <= code_int <= 89398 {
            return "Pathology/Laboratory";
        } elif 90281 <= code_int <= 99199 {
            return "Medicine";
        } elif 99500 <= code_int <= 99607 {
            return "Category II";
        } else {
            return "Category III";
        }
    } except Exception {
        return "Unknown";
    }
}
