# LLM-powered insight generation, answer synthesis, cluster summarization

obj InsightGeneration {
    has title: str;
    has description: str;
    has confidence: float;
    has analogy: str;
}

obj ClusterSummary {
    has label: str;
    has theme: str;
    has key_concepts: list[str];
    has knowledge_level: str;
}


sem generate_insight = """
Given a path through a knowledge graph from a start concept to an end concept,
generate a non-obvious insight that connects them. The insight should be something a person
might not notice on their own - a hidden analogy, a shared underlying principle, or a
transferable mental model. Return a compelling title, a 2-3 sentence description explaining
the connection, a confidence score (0.0 to 1.0 based on how strong and genuine the connection
is), and a one-sentence analogy that makes the insight memorable.
""";

sem synthesize_answer = """
Synthesize an answer to a question using knowledge paths through a graph.
The answer should explain the conceptual journey - how one concept connects to another
through intermediate ideas. Reference specific concepts from the paths. Highlight any
surprising intermediate connections. The answer should feel like a knowledgeable mentor
explaining connections, not a search engine returning results. Keep it to 3-5 sentences.
""";

sem generate_cluster_summary = """
Given a list of concepts and their descriptions that form a knowledge cluster, generate
a summary. Return: a short label (2-4 words, like 'Bayesian Machine Learning' or
'Startup Growth Metrics'), a theme sentence describing what unifies these concepts,
the 3-5 most important concepts in the cluster, and a knowledge level assessment
(surface, intermediate, or deep based on concept count and depth).
""";


def generate_insight(
    start_concept: str,
    end_concept: str,
    path: list[str],
    path_descriptions: list[str]
) -> InsightGeneration by llm(temperature=0.7);

def synthesize_answer(
    question: str,
    paths: list[dict],
    node_contexts: list[dict]
) -> str by llm(temperature=0.5);

def generate_cluster_summary(
    concepts: list[str],
    descriptions: list[str]
) -> ClusterSummary by llm(temperature=0.3);
