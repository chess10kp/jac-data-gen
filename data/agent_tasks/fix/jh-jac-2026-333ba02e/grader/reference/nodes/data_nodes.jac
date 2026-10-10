# nodes/data_nodes.jac
# ── ALL DATA CONTAINER NODES ─────────────────────────

# Holds each uploaded document
node DocumentNode {
    has filename: str = "";
    has content: str = "";
    has doc_type: str = "";
}

# Holds each piece of extracted evidence
node EvidenceNode {
    has evidence_type: str = "";
    has description: str = "";
    has source_doc: str = "";
    has confidence: float = 0.0;
}

# Holds the fraud timeline
node TimelineNode {
    has events: list = [];
    has fraud_start: str = "";
    has fraud_end: str = "";
    has total_duration_months: int = 0;
}

# Holds falsity legal element
node FalsityNode {
    has evidence_list: list = [];
    has falsity_type: str = "";
    has strength_score: float = 0.0;
    has summary: str = "";
}

# Holds scienter legal element
node ScientorNode {
    has evidence_list: list = [];
    has knowledge_type: str = "";
    has strength_score: float = 0.0;
    has summary: str = "";
}

# Holds materiality legal element
node MaterialityNode {
    has evidence_list: list = [];
    has government_relied: bool = False;
    has strength_score: float = 0.0;
    has summary: str = "";
}

# Holds causation legal element
node CausationNode {
    has evidence_list: list = [];
    has causal_chain: str = "";
    has strength_score: float = 0.0;
    has summary: str = "";
}

# Holds the final case memo output
node CaseMemoNode {
    has case_summary: str = "";
    has defendant: str = "";
    has total_false_claims: int = 0;
    has base_damages: float = 0.0;
    has treble_damages: float = 0.0;
    has per_claim_penalty: float = 0.0;
    has total_exposure: float = 0.0;
    has gap_analysis: list = [];
    has overall_strength: float = 0.0;
}