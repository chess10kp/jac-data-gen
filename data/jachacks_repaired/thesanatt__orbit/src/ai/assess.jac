# LLM-powered relationship assessment, contradiction detection, path scoring

obj RelationshipAssessment {
    has related: bool;
    has relationship_type: str;
    has strength: float;
    has explanation: str;
}

obj ContradictionAssessment {
    has contradicts: bool;
    has tension: str;
    has severity: float;
}

obj PathRelevanceScore {
    has relevance: float;
    has explanation: str;
    has key_connections: list[str];
}


sem assess_relationship = """
Assess whether two concepts are meaningfully related. Consider semantic similarity,
causal connections, analogical parallels, and prerequisite relationships. Return whether
they are related, what type of relationship exists (relates_to, builds_upon, contradicts,
or inspired_by), the strength of the relationship (0.0 to 1.0), and a brief explanation.
Be selective - only mark concepts as related if there is a genuine intellectual connection,
not just surface-level word overlap.
""";

sem detect_contradiction = """
Determine if two claims contradict each other. Claims may directly conflict, be in logical
tension, or represent incompatible perspectives. Return whether they contradict, a description
of the tension, and severity (0.0 = minor nuance difference, 1.0 = direct logical
contradiction). Only flag genuine contradictions, not complementary perspectives on the
same topic.
""";

sem score_path_relevance = """
Given a question and a path of concepts through a knowledge graph, score how relevant this
path is to answering the question. Consider: does the path connect concepts that help answer
the question? Are the intermediate concepts logical stepping stones? Return a relevance
score (0.0 to 1.0), an explanation of why this path is or isn't relevant, and a list of
the key connections along the path that matter most.
""";


def assess_relationship(
    concept_a: str,
    desc_a: str,
    concept_b: str,
    desc_b: str
) -> RelationshipAssessment by llm(temperature=0.1);

def detect_contradiction(
    claim_a: str,
    claim_b: str
) -> ContradictionAssessment by llm(temperature=0.0);

def score_path_relevance(
    question: str,
    path_concepts: list[str],
    path_descriptions: list[str]
) -> PathRelevanceScore by llm(temperature=0.2);
