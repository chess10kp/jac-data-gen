"""
TruthForge AI - Core Node Definitions
Defines all node types for the debate and reasoning graph
"""

# Base node for all debate participants
node BaseNode {
    has id: str;
    has created_at: str;
    has metadata: dict = {};
}

# Question node - represents the user's question/topic
node Question(BaseNode) {
    has text: str;
    has complexity: float = 0.0;  # Estimated by PlannerWalker
    has domain: str = "";         # Topic domain (science, politics, ethics, etc.)
    has subtopics: list[str] = [];
    has estimated_agents_needed: list[str] = [];
}

# Topic node - extracted main topic from question
node Topic(BaseNode) {
    has name: str;
    has category: str;
    has description: str = "";
    has related_topics: list[str] = [];
    has confidence: float = 0.0;
}

# Claim node - a supporting thesis position
node Claim(BaseNode) {
    has statement: str;
    has strength: float = 0.0;    # How strong is this claim (0-1)
    has reasoning: str = "";
    has key_points: list[str] = [];
    has assumptions: list[str] = [];
    has supporting_count: int = 0;
}

# CounterClaim node - attacks thesis claims
node CounterClaim(BaseNode) {
    has statement: str;
    has strength: float = 0.0;
    has reasoning: str = "";
    has key_points: list[str] = [];
    has assumptions: list[str] = [];
    has attacks_count: int = 0;
}

# Evidence node - supporting data/facts
node Evidence(BaseNode) {
    has content: str;
    has source: str = "";
    has credibility_score: float = 0.0;  # 0-1 scale
    has evidence_type: str = "";         # "statistical", "logical", "empirical", "anecdotal"
    has date_published: str = "";
    has retrieval_method: str = "";      # "web_search", "api", "knowledge_base"
}

# Verdict node - referee's evaluation
node Verdict(BaseNode) {
    has evaluation: str;
    has logic_quality_score: float = 0.0;      # 0-1
    has evidence_strength_score: float = 0.0;   # 0-1
    has assumption_validity: float = 0.0;       # 0-1
    has overall_confidence: float = 0.0;        # 0-1
    has key_findings: list[str] = [];
    has reasoning_quality: str = "";
}

# DebateSession node - container for complete reasoning cycle
node DebateSession(BaseNode) {
    has session_id: str;
    has question_id: str;
    has status: str = "pending";           # pending, in_progress, completed
    has complexity_level: str = "unknown"; # simple, moderate, complex
    has agents_activated: list[str] = [];
    has stage: int = 0;                    # Current stage of debate
    has total_stages: int = 0;
}

# PlanStep node - represents planning decision
node PlanStep(BaseNode) {
    has step_number: int;
    has agent_name: str;
    has reason: str = "";
    has priority: float = 0.0;
    has dependencies: list[str] = [];
}

# MemoryEntry node - stored reasoning from prior sessions
node MemoryEntry(BaseNode) {
    has question: str;
    has summary: str;
    has claims: list[str] = [];
    has counter_claims: list[str] = [];
    has verdict: str = "";
    has confidence: float = 0.0;
    has timestamp: str = "";
    has relevance_score: float = 0.0;
}

# SynthesisResult node - final output
node SynthesisResult(BaseNode) {
    has analysis: str;
    has supporting_signals: list[str] = [];
    has counterarguments: list[str] = [];
    has confidence: str = "";
    has final_answer: str = "";
    has reasoning_chain: list[str] = [];
}

# MemoryRecord alias for backward compatibility
node MemoryRecord(MemoryEntry) {
}
