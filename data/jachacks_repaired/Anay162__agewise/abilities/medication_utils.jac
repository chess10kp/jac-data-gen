"""Medication and prescription utility functions."""

# Common drug-drug interaction categories (simplified — not for clinical use)
glob HIGH_RISK_INTERACTIONS: list[dict] = [
    {
        "drug_a": "warfarin",
        "drug_b": "aspirin",
        "severity": "HIGH",
        "description": "Increased bleeding risk — monitor INR closely"
    },
    {
        "drug_a": "metformin",
        "drug_b": "contrast dye",
        "severity": "HIGH",
        "description": "Hold metformin before/after contrast procedures"
    },
    {
        "drug_a": "ace inhibitor",
        "drug_b": "potassium supplement",
        "severity": "MEDIUM",
        "description": "Risk of hyperkalemia — monitor potassium levels"
    },
    {
        "drug_a": "ssri",
        "drug_b": "tramadol",
        "severity": "HIGH",
        "description": "Serotonin syndrome risk"
    }
];

# Common Medicare Part D coverage gap thresholds (2026)
glob PART_D_THRESHOLDS: dict = {
    "deductible": 590.0,          # 2026 Part D deductible
    "initial_coverage_limit": 5030.0,
    "catastrophic_threshold": 8000.0,
    "coverage_gap_oop_threshold": 8000.0
};
# Drug tier levels (typical formulary)
glob DRUG_TIERS: dict = {
    1: "Preferred Generic",
    2: "Non-Preferred Generic",
    3: "Preferred Brand",
    4: "Non-Preferred Brand",
    5: "Specialty"
};
"""
Simple interaction check between two drug names (lowercased keywords).
Returns interaction dict if found, or empty dict.
Note: Not for clinical use — use a proper drug database in production.
"""
def check_drug_interaction(drug_a: str, drug_b: str) -> dict {
    a_lower = drug_a.lower();
    b_lower = drug_b.lower();
    for interaction in HIGH_RISK_INTERACTIONS {
        if ((interaction["drug_a"] in a_lower and interaction["drug_b"] in b_lower) or
            (interaction["drug_a"] in b_lower and interaction["drug_b"] in a_lower)) {
            return interaction;
        }
    }
    return {};
}

"""
Estimate which Part D coverage stage a patient is in based on YTD drug spend.
"""
def estimate_part_d_cost_stage(ytd_drug_spend: float) -> str {
    if ytd_drug_spend < PART_D_THRESHOLDS["deductible"] {
        return "DEDUCTIBLE";
    } elif ytd_drug_spend < PART_D_THRESHOLDS["initial_coverage_limit"] {
        return "INITIAL_COVERAGE";
    } elif ytd_drug_spend < PART_D_THRESHOLDS["catastrophic_threshold"] {
        return "COVERAGE_GAP";
    } else {
        return "CATASTROPHIC";
    }
}

"""
Parse a prescription sig (directions) into structured components.
e.g. 'Take 1 tablet by mouth twice daily with food'
Returns dict with dose, route, frequency, notes.
"""
def parse_sig_code(sig: str) -> dict {
    sig_lower = sig.lower();
    # Frequency detection
    frequency = "unknown";
    if "once daily" in sig_lower or "qd" in sig_lower or "every day" in sig_lower {
        frequency = "once_daily";
    } elif "twice daily" in sig_lower or "bid" in sig_lower {
        frequency = "twice_daily";
    } elif "three times" in sig_lower or "tid" in sig_lower {
        frequency = "three_times_daily";
    } elif "four times" in sig_lower or "qid" in sig_lower {
        frequency = "four_times_daily";
    } elif "as needed" in sig_lower or "prn" in sig_lower {
        frequency = "as_needed";
    }
    # Route detection
    route = "oral";
    if "injection" in sig_lower or "inject" in sig_lower {
        route = "injection";
    } elif "topical" in sig_lower or "apply" in sig_lower {
        route = "topical";
    } elif "inhale" in sig_lower or "inhal" in sig_lower {
        route = "inhalation";
    }
    return {
        "raw": sig,
        "frequency": frequency,
        "route": route
    };
}
