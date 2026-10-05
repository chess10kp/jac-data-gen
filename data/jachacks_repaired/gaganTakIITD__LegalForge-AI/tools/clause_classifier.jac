"""Deterministic clause taxonomy -- shared across all walkers."""

glob FOUNDATIONAL_KINDS = {
    "party_block", "recital", "definition", "signature",
    "governing_law", "notices", "force_majeure"
};

def classify_clause(text: str, section: str) -> str {
    combined = (section + "\n" + text).lower();
    head = section.lower();
    if "limitation of liability" in head or "liability cap" in head or "remedies" in head {
        return "liability";
    }
    if "indemnif" in head {
        return "indemnification";
    }
    if "non-compete" in head or "noncompete" in head {
        return "non_compete";
    }
    if "data process" in head or "privacy" in head or "gdpr" in head {
        return "data_processing";
    }
    if "data ownership" in head or "user data" in head {
        return "data_processing";
    }
    if "auto-renew" in head or "renewal" in head {
        return "renewal";
    }
    if "termination" in head or "term of agreement" in head {
        return "termination";
    }
    if "intellectual property" in head or "work product" in head {
        return "ip_assignment";
    }
    if "warrant" in head {
        return "warranty";
    }
    if "confidential" in head {
        return "confidentiality";
    }
    if "governing law" in head {
        return "governing_law";
    }
    if "definition" in head {
        return "definition";
    }
    if "force majeure" in head {
        return "force_majeure";
    }
    if "notice" in head {
        return "notices";
    }
    if "indemnif" in combined and "shall indemnify" in combined {
        return "indemnification";
    }
    if "liability" in combined and ("shall not exceed" in combined or "$" in combined) {
        return "liability";
    }
    if "personal data" in combined or "subprocessor" in combined {
        return "data_processing";
    }
    if "auto-renew" in combined or "renews automatically" in combined {
        return "renewal";
    }
    if "terminate" in combined {
        return "termination";
    }
    if "owns" in combined and "work" in combined {
        return "ip_assignment";
    }
    if "confidential information" in combined {
        return "confidentiality";
    }
    if "by and between" in combined {
        return "party_block";
    }
    return "general";
}
