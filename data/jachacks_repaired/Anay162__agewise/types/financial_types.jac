"""Financial account and transaction type definitions."""

# Plaid account types
glob ACCOUNT_TYPES: list[str] = [
    "CHECKING",
    "SAVINGS",
    "CREDIT_CARD",
    "MONEY_MARKET",
    "CD",
    "BROKERAGE",
    "IRA",
    "ROTH_IRA",
    "401K",
    "HSA",
    "PENSION"
];

# Transaction categories for healthcare/elder finance
glob TRANSACTION_CATEGORIES: list[str] = [
    "MEDICAL_COPAY",
    "PRESCRIPTION",
    "INSURANCE_PREMIUM",
    "HOSPITAL_BILL",
    "DENTAL",
    "VISION",
    "THERAPY",
    "HOME_HEALTH",
    "UTILITY",
    "RENT_MORTGAGE",
    "GROCERY",
    "SUBSCRIPTION",
    "CHARITABLE_DONATION",
    "LARGE_TRANSFER",
    "UNKNOWN"
];

# Recurring bill detection patterns
glob RECURRING_KEYWORDS: list[str] = [
    "insurance premium", "medicare", "aarp", "supplemental",
    "electric", "gas", "water", "internet", "phone", "cable",
    "netflix", "hulu", "spotify", "amazon prime", "apple",
    "rent", "mortgage", "property tax", "homeowners",
    "auto insurance", "life insurance", "long-term care"
];

# Suspicious transaction indicators (potential scam patterns)
glob SCAM_INDICATORS: list[str] = [
    "wire transfer",
    "western union",
    "moneygram",
    "gift card",
    "cryptocurrency",
    "bitcoin",
    "lottery",
    "sweepstakes",
    "prize",
    "irs payment",
    "social security",
    "warrant",
    "arrest"
];

# High-value thresholds requiring review
glob HIGH_VALUE_THRESHOLDS: dict = {
    "single_transaction": 2500.0,
    "daily_total": 5000.0,
    "weekly_total": 10000.0,
    "new_payee": 1000.0
};