# LLM-powered concept, people, and relationship extraction

obj ConceptExtraction {
    has name: str;
    has description: str;
    has domain: str;
    has depth: str;
}

obj PersonExtraction {
    has name: str;
    has context: str;
}

obj RelationshipExtraction {
    has source_concept: str;
    has target_concept: str;
    has relationship_type: str;
    has strength: float;
    has explanation: str;
}


sem extract_concepts = """
Extract key concepts from the given text. Return a list of concepts, each with:
name (concise label), description (1-2 sentences explaining the concept),
domain (e.g., machine_learning, philosophy, business, science, arts, cross_domain),
and depth (surface for briefly mentioned, intermediate for explained, deep for
thoroughly discussed). Focus on substantive intellectual concepts, not trivial mentions.
The source_type parameter indicates the format of the input (article, tweet, note,
highlight, conversation, lecture) - adjust extraction granularity accordingly:
tweets yield fewer, broader concepts; articles yield more, deeper ones.
""";

sem extract_people = """
Extract people mentioned in the text. Return their name and context
(how they relate to the content - e.g., 'author of the paper', 'proposed this theory',
'CEO of the company'). Only include real, named individuals - not pronouns or
generic references.
""";

sem extract_relationships = """
Given a list of concept names and their descriptions, identify relationships between them.
For each relationship, specify: source_concept and target_concept (exact names from the
input list), relationship_type (one of: relates_to, builds_upon, contradicts, inspired_by),
strength (0.0 to 1.0, where 1.0 is very strong), and explanation (brief description of
how they relate). Only include relationships that are meaningful and supported by the
concepts' definitions. Prefer fewer, high-quality relationships over many weak ones.
Use builds_upon when one concept is a prerequisite or foundation for another.
Use contradicts when concepts present opposing views or incompatible claims.
Use inspired_by when one concept historically or logically led to the development of another.
Use relates_to for all other meaningful connections.
""";


def extract_concepts(text: str, source_type: str) -> list[ConceptExtraction]
    by llm(temperature=0.3);

def extract_people(text: str) -> list[PersonExtraction]
    by llm(temperature=0.1);

def extract_relationships(concepts: list[str], descriptions: list[str]) -> list[RelationshipExtraction]
    by llm(temperature=0.3);
