import from pharma_nlp { parse_prescription, generate_risk_summary }

obj ExtractedDrugs {
    has drug_names: list[str];
    has conditions_mentioned: list[str];
}
