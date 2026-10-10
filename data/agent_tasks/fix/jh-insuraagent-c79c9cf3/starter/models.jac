# models.jac — typed data model for the Insurance Appeal Agent.
#
# These enums/objects double as schemas that constrain LLM output:
# when an `llm()`-typed function returns one of these types, byLLM
# forces the model to produce valid structured data.

# ---- Enums ---------------------------------------------------------------

enum DenialReason {
    NOT_MEDICALLY_NECESSARY,
    OUT_OF_NETWORK,
    PRIOR_AUTH_MISSING,
    EXPERIMENTAL_OR_INVESTIGATIONAL,
    CODING_ERROR,
    BENEFIT_EXCLUSION,
    OTHER
}

enum AppealStrength {
    WEAK,
    MODERATE,
    STRONG,
    VERY_STRONG
}

# ---- Structured value objects (used as LLM-typed returns) ---------------

obj PolicyClause {
    has section: str,
        title: str,
        text: str,
        relevance_note: str = "";
}

obj Contradiction {
    has denial_quote: str,
        policy_quote: str,
        clause_section: str,
        explanation: str;
}

obj AppealLetter {
    has subject: str,
        salutation: str,
        body: str,
        citations: list[str],
        closing: str;
}

# ---- Persistent graph nodes (attached to root) --------------------------

node Claim {
    has claim_id: str,
        patient_name: str,
        member_id: str,
        cpt_code: str,
        date_of_service: str,
        billed_amount: float,
        denial_text: str,
        clinical_record: str = "";
}

node Policy {
    has policy_id: str,
        plan_name: str,
        full_text: str;
}

node Appeal {
    has appeal_id: str,
        claim_id: str,
        policy_id: str,
        denial_reason: DenialReason,
        strength: AppealStrength,
        contradictions_json: str,   # serialized list[Contradiction]
        letter_subject: str,
        letter_body: str,
        citations_json: str,        # serialized list[str]
        created_at: str;
}
