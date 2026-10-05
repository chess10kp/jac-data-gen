# LLM-powered path narration, contradiction descriptions, daily digests

obj PathNarration {
    has narration: str;
}

obj ContradictionDescription {
    has description: str;
}

obj DailyDigest {
    has digest: str;
}


sem narrate_path = """
Narrate a walker's journey through a knowledge graph path as if telling a story. Describe
how each concept connects to the next, what the edges between them represent, and how this
path answers or relates to the original question. Use engaging, first-person language like
'Starting from X, we follow the thread to Y, because...' Make it feel like an intellectual
adventure, not a dry listing. Keep it to 3-5 sentences.
""";

sem describe_contradiction = """
Describe a contradiction found between two claims in a user's knowledge graph. Present both
sides fairly, explain the tension, and suggest how the user might resolve or reconcile the
contradiction. Be intellectually honest - some contradictions are genuine paradoxes, others
are context-dependent. Keep it to 3-4 sentences.
""";

sem generate_digest = """
Generate a daily knowledge digest summarizing what's happening in the user's knowledge graph.
Mention new insights discovered (if any), knowledge connections that are fading and might
need review, and areas where the graph has gaps. Write in a friendly, encouraging tone -
like a knowledgeable assistant giving a morning briefing. Keep it to 4-6 sentences.
""";


def narrate_path(
    path_nodes: list[str],
    path_edges: list[str],
    question: str
) -> PathNarration by llm(temperature=0.6);

def describe_contradiction(
    claim_a: str,
    source_a: str,
    claim_b: str,
    source_b: str
) -> ContradictionDescription by llm(temperature=0.4);

def generate_digest(
    new_insights: list[str],
    decaying_edges: list[str],
    knowledge_gaps: list[str]
) -> DailyDigest by llm(temperature=0.5);
