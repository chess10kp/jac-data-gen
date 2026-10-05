"""LegalForge AI -- Tool Functions used by agents."""

import from datetime { datetime }
import json;


def get_timestamp() -> str {
    return datetime.now().isoformat();
}


def search_legal_precedent(query: str) -> list {
    precedents = [
        {"case": "Carnival Cruise Lines v. Shute (1991)", "relevance": "Forum selection clauses enforceability"},
        {"case": "ProCD v. Zeidenberg (1996)", "relevance": "Shrinkwrap license enforceability"},
        {"case": "AT&T Mobility v. Concepcion (2011)", "relevance": "Arbitration clause validity"},
        {"case": "Lochner v. New York (1905)", "relevance": "Unconscionable contract terms"}
    ];
    results = [];
    for p in precedents {
        if query.lower() in p["relevance"].lower() or query.lower() in p["case"].lower() {
            results.append(p);
        }
    }
    return results if results else [precedents[0]];
}


def search_statute_db(jurisdiction: str, topic: str) -> list {
    statutes = {
        "US": [
            {"name": "UCC Article 2", "topic": "commercial transactions", "sections": ["2-302", "2-316"]},
            {"name": "SEC Rule 10b-5", "topic": "securities fraud", "sections": ["Anti-fraud"]},
            {"name": "FTC Act Section 5", "topic": "unfair practices", "sections": ["Section 5"]},
            {"name": "CCPA", "topic": "consumer privacy", "sections": ["1798.100-199"]},
            {"name": "SOX Act", "topic": "financial reporting", "sections": ["302", "404"]}
        ],
        "EU": [
            {"name": "GDPR", "topic": "data protection", "sections": ["Art. 5-43"]},
            {"name": "EU Consumer Rights Directive", "topic": "consumer contracts", "sections": ["Art. 6", "Art. 9"]}
        ]
    };
    results = [];
    for s in statutes.get(jurisdiction, statutes["US"]) {
        if topic.lower() in str(s["topic"]).lower() {
            results.append(s);
        }
    }
    return results if results else statutes.get(jurisdiction, statutes["US"]);
}


def get_regulation_text(statute_name: str) -> str {
    texts = {
        "UCC Article 2": "Article 2 of the Uniform Commercial Code governs sales of goods. Section 2-302 addresses unconscionability.",
        "GDPR": "The General Data Protection Regulation establishes rules for the processing of personal data of EU residents.",
        "CCPA": "The California Consumer Privacy Act gives California residents rights over their personal data."
    };
    return texts.get(statute_name, f"Regulation text for {statute_name} not found in local database.");
}


def calculate_penalty(violation_type: str, contract_value: float) -> dict {
    penalty_rates = {
        "unconscionability": 0.15,
        "data_breach": 0.20,
        "fraud": 0.50,
        "unfair_practice": 0.10,
        "non_compliance": 0.05
    };
    rate = penalty_rates.get(violation_type, 0.05);
    return {
        "violation_type": violation_type,
        "contract_value": contract_value,
        "estimated_penalty": contract_value * rate,
        "penalty_rate": rate
    };
}


def get_industry_benchmark(industry: str, clause_type: str) -> float {
    benchmarks = {
        "technology": {"obligation": 0.35, "indemnity": 0.55, "termination": 0.25, "liability": 0.45},
        "finance": {"obligation": 0.40, "indemnity": 0.60, "termination": 0.30, "liability": 0.50},
        "healthcare": {"obligation": 0.50, "indemnity": 0.70, "termination": 0.35, "liability": 0.65}
    };
    industry_data = benchmarks.get(industry, benchmarks["technology"]);
    return industry_data.get(clause_type, 0.3);
}


def calculate_exposure(clause_text: str, contract_value: float) -> dict {
    high_risk_terms = ["unlimited", "indemnify", "hold harmless", "no cap", "sole discretion", "waive"];
    risk_count = 0;
    for term in high_risk_terms {
        if term in clause_text.lower() {
            risk_count += 1;
        }
    }
    exposure_pct = min(1.0, risk_count * 0.15 + 0.1);
    return {
        "exposure_amount": contract_value * exposure_pct,
        "exposure_percentage": exposure_pct * 100,
        "risk_terms_found": risk_count
    };
}


# Windows-safe report helper: strip chars that break console print in jac serve.
def sanitize_for_report(data: any) -> any {
    out = data;
    ::py::
    import json

    def _fix(v):
        if isinstance(v, str):
            s = v.replace("\u00a7", "Sec.").replace("\u2014", "-").replace("\u2013", "-")
            return s.encode("ascii", "replace").decode("ascii")
        if isinstance(v, dict):
            return {str(k): _fix(val) for k, val in v.items()}
        if isinstance(v, list):
            return [_fix(i) for i in v]
        return v

    try:
        out = _fix(data)
    except Exception:
        out = data
    ::py::
    return out;
}
