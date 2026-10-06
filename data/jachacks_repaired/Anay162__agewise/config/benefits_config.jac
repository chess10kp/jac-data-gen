"""Benefits configuration — Medicare parts, common supplement plans, and coverage lookup."""

# Medicare enrollment periods
glob ENROLLMENT_PERIODS: dict = {
    "IEP": "Initial Enrollment Period — 7 months around 65th birthday",
    "GEP": "General Enrollment Period — January 1 to March 31 each year",
    "SEP": "Special Enrollment Period — based on qualifying life event",
    "AEP": "Annual Election Period (Medicare Advantage) — Oct 15 to Dec 7",
    "OEP": "Open Enrollment Period (Medicare Advantage) — Jan 1 to Mar 31"
};
# Medicare Supplement (Medigap) plan coverage matrix (2026)
glob MEDIGAP_COVERAGE: dict = {
    "A": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": False, "part_b_deductible": False,
        "foreign_emergency": False, "excess_charges": False
    },
    "B": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": True, "part_b_deductible": False,
        "foreign_emergency": False, "excess_charges": False
    },
    "D": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": True, "part_b_deductible": False,
        "foreign_emergency": True, "excess_charges": False
    },
    "F": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": True, "part_b_deductible": True,
        "foreign_emergency": True, "excess_charges": True
    },
    "G": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": True, "part_b_deductible": False,
        "foreign_emergency": True, "excess_charges": True
    },
    "N": {
        "part_a_coinsurance": True, "part_b_coinsurance": True,
        "part_a_deductible": True, "part_b_deductible": False,
        "foreign_emergency": True, "excess_charges": False
    }
};
# Extra Help (Low Income Subsidy) thresholds for 2026
glob EXTRA_HELP_THRESHOLDS: dict = {
    "full_subsidy_income_individual": 20385.0,   # 135% FPL
    "partial_subsidy_income_individual": 24165.0, # 150% FPL
    "full_subsidy_assets_individual": 10590.0,
    "partial_subsidy_assets_individual": 16630.0
};
# Medicare Savings Programs (2026 income limits — approximate)
glob MSP_PROGRAMS: dict = {
    "QMB": {"name": "Qualified Medicare Beneficiary", "income_limit_individual": 1255.0},
    "SLMB": {"name": "Specified Low-Income Medicare Beneficiary", "income_limit_individual": 1478.0},
    "QI": {"name": "Qualifying Individual", "income_limit_individual": 1660.0},
    "QDWI": {"name": "Qualified Disabled and Working Individuals", "income_limit_individual": 4945.0}
};