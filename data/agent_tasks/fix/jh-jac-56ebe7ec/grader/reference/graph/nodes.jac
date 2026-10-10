node Drug {
    has name: str;
    has generic_name: str;
    has drug_class: str;
    has cyp_pathway: list[str];
    has half_life_hours: float;
}

node Condition {
    has name: str;
    has icd_code: str;
    has contraindicated_drugs: list[str];
}

node MedProfile {
    has user_id: str = "default";
    has drug_names: list[str] = [];
    has conditions: list[str] = [];
}

node RiskReport {
    has flagged_pairs: list[any] = [];
    has severity_max: int = 0;
    has summary: str = "";
    has generated_at: str = "";
}
