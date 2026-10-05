"""
TruthForge AI - Edge Definitions
Defines all edge types connecting nodes in the reasoning graph
"""

# supports - Claim or Evidence supports a thesis/statement
edge supports {
    has weight: float = 1.0;
    has strength: float = 0.0;      # 0-1 confidence
    has explanation: str = "";
    has timestamp: str = "";
}

# attacks - CounterClaim attacks a Claim
edge attacks {
    has weight: float = 1.0;
    has strength: float = 0.0;      # How strong is the attack
    has explanation: str = "";
    has timestamp: str = "";
}

# validated_by - Claim validated by Evidence
edge validated_by {
    has weight: float = 1.0;
    has validation_score: float = 0.0;
    has evidence_quality: float = 0.0;
    has timestamp: str = "";
}

# related_to - Nodes with related topics/content
edge related_to {
    has weight: float = 1.0;
    has similarity_score: float = 0.0;
    has relation_type: str = "";    # "topical", "causal", "comparative"
    has timestamp: str = "";
}

# generated_from - Node derivation source
edge generated_from {
    has weight: float = 1.0;
    has generation_method: str = "";  # "planner", "thesis_walker", etc.
    has confidence: float = 0.0;
    has timestamp: str = "";
}

# discussed_in - Node is part of a debate session
edge discussed_in {
    has weight: float = 1.0;
    has discussion_depth: int = 0;
    has stage: int = 0;
    has timestamp: str = "";
}

# refines - Node evolves from prior reasoning
edge refines {
    has weight: float = 1.0;
    has improvement_score: float = 0.0;
    has changes: list[str] = [];
    has timestamp: str = "";
}

# contradicts - Node directly contradicts another
edge contradicts {
    has weight: float = 1.0;
    has contradiction_level: float = 0.0;  # 0-1 intensity
    has explanation: str = "";
    has timestamp: str = "";
}

# contributes_to - Node contributes to verdict/conclusion
edge contributes_to {
    has weight: float = 1.0;
    has contribution_score: float = 0.0;
    has contribution_type: str = "";  # "supporting", "constraining", "neutral"
    has timestamp: str = "";
}

# references - Node references an external source or document
edge references {
    has weight: float = 1.0;
    has citation: str = "";
    has url: str = "";
    has timestamp: str = "";
}

# similar_to - Node is semantically similar to another node
edge similar_to {
    has weight: float = 1.0;
    has similarity_score: float = 0.0;  # 0-1
    has relation_type: str = "semantic";
    has timestamp: str = "";
}
