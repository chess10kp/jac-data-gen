"""LegalForge AI — Graph Node & Edge Definitions (Jac-Native OSP Design)"""

# === DOCUMENT LAYER ===

node Contract {
    has title: str = "";
    has upload_date: str = "";
    has parties: list = [];
    has jurisdiction: str = "US";
    has risk_score: float = 0.0;
    has status: str = "pending";
}

node Clause {
    has clause_id: str = "";
    has text: str = "";
    has section: str = "";
    has page_number: int = 1;
    has clause_type: str = "obligation";
    # Semantic kind written by ContradictionWalker.classify_clause and reused
    # by Compliance / Risk / Negotiation walkers so every walker agrees on what
    # this clause is *about* (liability / indemnification / ip_assignment /
    # data_processing / non_compete / termination / renewal / warranty /
    # confidentiality / governing_law / definition / party_block / recital /
    # signature / notices / force_majeure / general).
    has clause_kind: str = "";
    has risk_level: str = "low";
    has risk_score: float = 0.0;
    has ai_summary: str = "";
    has flagged: bool = False;
}

node Definition {
    has term: str = "";
    has meaning: str = "";
    has scope: str = "global";
}

node Party {
    has name: str = "";
    has role: str = "";
    has obligations: list = [];
    has rights: list = [];
}

node Obligation {
    has description: str = "";
    has deadline: str = "";
    has penalty: str = "";
    has is_conditional: bool = False;
    has condition: str = "";
}

# === SECURITY LAYER ===

node AuditEntry {
    has timestamp: str = "";
    has agent_name: str = "";
    has action: str = "";
    has finding: str = "";
    has confidence: float = 0.0;
}

node UserSession {
    has user_id: str = "";
    has role: str = "viewer";
    has permissions: list = [];
    has session_token: str = "";
}

# === EDGES ===

edge contains {}
edge defines {}
edge involves {}

edge modifies {
    has scope: str = "extends";
}

edge contradicts {
    has severity: str = "potential";
    has explanation: str = "";
    has confidence: float = 0.0;
}

edge references {
    has context: str = "";
}

edge exempts {
    has condition: str = "";
}

edge binds {
    has enforcement: str = "strict";
}

edge governed_by {}
edge audited_by {}
