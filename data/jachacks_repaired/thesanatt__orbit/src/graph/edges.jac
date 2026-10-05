# Edge archetypes — strength decays via Ebbinghaus: S(t) = S_0 * e^(-lambda*t) + S_base

# General semantic relationship between concepts.
edge relates_to {
    has strength: float = 0.5,
        relationship: str = "",
        created_at: float = 0.0,
        last_reinforced: float = 0.0,
        reinforcement_count: int = 1;
}

# Directional: source concept is foundation for target.
edge builds_upon {
    has strength: float = 0.7,
        explanation: str = "",
        created_at: float = 0.0;
}

# Conflicting concepts or claims.
edge contradicts {
    has strength: float = 0.5,
        tension: str = "",
        resolved: bool = False,
        created_at: float = 0.0;
}

# Links back to source material.
edge sourced_from {
    has relevance: float = 0.8,
        excerpt: str = "";
}

# Learning X led to thinking about Y.
edge inspired_by {
    has created_at: float = 0.0,
        context: str = "";
}

# Concept applied in a project.
edge applied_in {
    has how: str = "";
}

# Person referenced or discussed a concept.
edge mentioned_by {
    has context: str = "";
}

# Time-ordered connection.
edge temporal {
    has timestamp: float = 0.0,
        sequence_type: str = "";
}
