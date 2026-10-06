"""Money and billing amount utility functions."""

"""
Parse a dollar amount string to float.
Handles: '$1,234.56', '1234.56', '($500.00)', '-$500.00'
"""
def parse_dollar_amount(amount_str: str) -> float {
    try {
        cleaned = amount_str.strip();
        # Handle parenthetical negatives like (500.00)
        negative = cleaned.startswith("(") and cleaned.endswith(")");
        # Remove currency symbols, commas, parentheses
        cleaned = cleaned.replace("$", "").replace(",", "").replace("(", "").replace(")", "").strip();
        value = float(cleaned);
        return -value if negative else value;
    } except Exception {
        return 0.0;
    }
}

"""Format a float as USD currency string."""
def format_currency(amount: float) -> str {
    if amount < 0 {
        return f"(${abs(amount):,.2f})";
    }
    return f"${amount:,.2f}";
}

"""Calculate patient coinsurance (default 20% Medicare Part B)."""
def calc_coinsurance(allowed_amount: float, coinsurance_rate: float = 0.20) -> float {
    return round(allowed_amount * coinsurance_rate, 2);
}

"""
Calculate patient's total out-of-pocket for a service.
= deductible_applied + coinsurance on remaining balance.
"""
def calc_patient_responsibility(
    allowed_amount: float,
    paid_amount: float,
    deductible_remaining: float = 0.0
) -> float {
    deductible_applied = min(deductible_remaining, allowed_amount);
    post_deductible = allowed_amount - deductible_applied;
    coinsurance = calc_coinsurance(post_deductible);
    return round(deductible_applied + coinsurance, 2);
}

"""
Detect potential balance billing (provider charging more than allowed).
Returns True if patient seems to have been billed more than their legal responsibility.
"""
def is_balance_billing(charge_amount: float, allowed_amount: float, paid_amount: float, patient_paid: float) -> bool {
    if allowed_amount <= 0 {
        return False;
    }
    patient_legal_max = calc_coinsurance(allowed_amount) + 240.0;  # 2026 Part B deductible
    return patient_paid > patient_legal_max * 1.1;  # 10% tolerance
}

"""Sum amount_disputed across a list of dispute dicts."""
def sum_disputed_amounts(disputes: list[dict]) -> float {
    total = 0.0;
    for d in disputes {
        total += d.get("amount_disputed", 0.0);
    }
    return round(total, 2);
}
