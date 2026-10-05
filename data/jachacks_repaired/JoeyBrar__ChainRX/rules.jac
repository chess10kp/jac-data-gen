"""Compounding rules for multi-drug chain risk escalation."""

glob COMPOUNDING_RULES: dict[tuple, float] = {
    # Kidney cascade: NSAID reduces kidney function -> metformin/other accumulates
    ("reduces_kidney_function", "additive_kidney_stress"): 1.5,
    ("reduces_kidney_function", "reduced_clearance"): 1.6,
    ("additive_kidney_stress", "reduces_kidney_function"): 1.4,
    ("reduces_kidney_function", "hyperkalemia_risk"): 1.4,
    ("hyperkalemia_risk", "reduces_kidney_function"): 1.3,

    # Serotonin cascade: multiple serotonergic agents compound
    ("serotonin_increase", "serotonin_increase"): 1.8,

    # Bleeding cascade: anticoagulant + antiplatelet + NSAID
    ("bleeding_risk", "bleeding_risk"): 1.7,
    ("bleeding_risk", "reduces_kidney_function"): 1.3,

    # QT prolongation cascade
    ("qt_prolongation", "qt_prolongation"): 1.6,
    ("qt_prolongation", "serotonin_increase"): 1.2,

    # CNS depression cascade
    ("cns_depression", "cns_depression"): 1.7,
    ("cns_depression", "serotonin_increase"): 1.3,

    # Hypotension cascade
    ("additive_hypotension", "reduces_kidney_function"): 1.4,
    ("additive_hypotension", "additive_hypotension"): 1.5,

    # Reduced clearance cascade: drug accumulation compounds with organ stress
    ("reduced_clearance", "reduced_clearance"): 1.5,
    ("reduced_clearance", "bleeding_risk"): 1.4,
    ("reduced_clearance", "qt_prolongation"): 1.4,
    ("reduced_clearance", "cns_depression"): 1.3,
    ("reduced_clearance", "additive_kidney_stress"): 1.4,

    # Hepatotoxicity cascade
    ("hepatotoxicity", "hepatotoxicity"): 1.6,
    ("hepatotoxicity", "reduced_clearance"): 1.4,

    # Hypoglycemia cascade
    ("additive_hypoglycemia", "additive_hypoglycemia"): 1.5,
    ("additive_hypoglycemia", "reduced_clearance"): 1.3,

    # Anticholinergic burden cascade
    ("anticholinergic_burden", "anticholinergic_burden"): 1.6,
    ("anticholinergic_burden", "cns_depression"): 1.4,
    ("cns_depression", "anticholinergic_burden"): 1.3,

    # Hyperkalemia cascade
    ("hyperkalemia_risk", "hyperkalemia_risk"): 1.5,
    ("hyperkalemia_risk", "additive_kidney_stress"): 1.4,
    ("additive_kidney_stress", "hyperkalemia_risk"): 1.4,

    # Cross-domain escalations
    ("bleeding_risk", "reduced_clearance"): 1.3,
    ("qt_prolongation", "reduced_clearance"): 1.3,
    ("serotonin_increase", "cns_depression"): 1.3,
    ("additive_hypotension", "cns_depression"): 1.3,
    ("additive_hypotension", "additive_kidney_stress"): 1.4
};

glob RISK_THRESHOLD: float = 0.6;

def get_multiplier(upstream: str, downstream: str) -> float {
    key = (upstream, downstream);
    if key in COMPOUNDING_RULES {
        return COMPOUNDING_RULES[key];
    }
    return 1.0;
}
