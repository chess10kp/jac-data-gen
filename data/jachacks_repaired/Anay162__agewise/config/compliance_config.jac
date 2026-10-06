"""Compliance configuration — HIPAA, CMS, and Medicare regulatory settings."""

# HIPAA data retention requirements
glob HIPAA_RETENTION: dict = {
    "medical_records": 6,       # years from last service
    "billing_records": 7,       # years from service date
    "audit_logs": 6,            # years
    "consent_forms": 6,         # years
    "business_associate_agreements": 6
};
# Medicare timely filing limits (days from service date)
glob TIMELY_FILING_LIMITS: dict = {
    "medicare_original": 365,        # 1 year
    "medicare_advantage": 365,
    "medicaid": 365,                 # varies by state
    "commercial": 180,               # typical
    "crossover_claims": 27           # months from service
};
# Medicare appeal deadlines (days from Notice of Denial)
glob APPEAL_DEADLINES: dict = {
    1: 120,   # Redetermination
    2: 180,   # Reconsideration (QIC)
    3: 60,    # ALJ Hearing
    4: 60,    # Medicare Appeals Council
    5: 60     # Federal District Court
};
# Minimum amounts for appeal levels (2026)
glob APPEAL_MIN_AMOUNTS: dict = {
    1: 0.0,
    2: 0.0,
    3: 180.0,    # ALJ — $180 minimum
    4: 0.0,
    5: 1760.0    # Federal court — $1,760 minimum
};
# Medicare Part B cost-sharing (2026)
glob MEDICARE_COST_SHARING: dict = {
    "part_b_deductible": 240.0,
    "part_b_coinsurance": 0.20,
    "part_a_deductible": 1676.0,
    "part_a_snf_days_1_20": 0.0,
    "part_a_snf_days_21_100": 209.50,
    "part_a_hospital_days_1_60": 0.0,
    "part_a_hospital_days_61_90": 419.0,
    "conversion_factor_2026": 33.29
};
# OIG exclusion check requirements
glob OIG_CHECK_REQUIRED: bool = True;
glob OIG_CHECK_FREQUENCY_DAYS: int = 30;
