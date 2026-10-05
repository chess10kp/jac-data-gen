"""
TruthForge AI - Configuration Constants
Centralized configuration for walkers and system behavior
Environment variables are read at runtime from .env file
"""

# Environment variables with defaults
# These are set from process.env or .env file at initialization
glob GEMINI_API_KEY = "";  # Set at runtime from process.env.GEMINI_API_KEY
glob GEMINI_MODEL = "gemini-2.0-flash";  # Can be overridden by process.env.GEMINI_MODEL
glob MAX_REASONING_DEPTH = 5;
glob DEFAULT_COMPLEXITY_THRESHOLD = 0.6;
glob CONFIDENCE_THRESHOLD = 0.7;

glob AGENT_TYPES = {
    "planner": "Orchestrates workflow based on complexity",
    "memory": "Retrieves related prior reasoning",
    "thesis": "Generates supporting claims",
    "antithesis": "Generates counter-claims",
    "evidence": "Gathers supporting evidence",
    "referee": "Evaluates logic and evidence",
    "synthesis": "Creates final structured output",
    "memory_update": "Persists reasoning to database"
};

glob COMPLEXITY_LEVELS = {
    "simple": {"threshold": 0.3, "agents": ["thesis", "antithesis", "referee", "synthesis"]},
    "moderate": {"threshold": 0.6, "agents": ["memory", "thesis", "antithesis", "evidence", "referee", "synthesis"]},
    "complex": {"threshold": 1.0, "agents": ["planner", "memory", "thesis", "antithesis", "evidence", "referee", "synthesis"]}
};

glob EVIDENCE_TYPES = ["statistical", "logical", "empirical", "anecdotal", "theoretical"];
glob RELATION_TYPES = ["supports", "attacks", "validated_by", "related_to", "generated_from", "discussed_in", "refines", "contradicts", "contributes_to"];

glob DB_PATH = "./truthforge.db";  # Can be overridden by process.env.TRUTHFORGE_DB_PATH
glob LOG_LEVEL = "info";  # debug, info, warn, error - can be overridden by process.env.LOG_LEVEL
