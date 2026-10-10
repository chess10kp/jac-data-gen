"""Memory engine data models for Trace."""

enum MemoryType {
    EVENT,
    PERSON,
    EMOTION,
    VALUE,
    THEME,
    DECISION,
    HABIT,
    PERIOD,
    PREFERENCE
}

enum RelationType {
    TEMPORAL,
    CAUSAL,
    EMOTIONAL,
    THEMATIC,
    INVOLVES,
    CONTRADICTS,
    REINFORCES
}

node MemoryNode {
    has content: str = "";
    has memory_type: str = "event";
    has timestamp: str = "";
    has confidence: float = 1.0;
    has source_hash: str = "";
    has embedding: list[float] = [];
    has importance: float = 0.5;
    has decay_rate: float = 0.01;
    has last_accessed: str = "";
    has access_count: int = 0;
    has user_confirmed: bool = False;
}

edge MemoryEdge {
    has relation_type: RelationType = RelationType.TEMPORAL;
    has strength: float = 1.0;
    has confidence: float = 1.0;
}
