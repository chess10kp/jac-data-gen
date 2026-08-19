"""Text-analysis LLM helpers with rich sem specs."""

sem classify = """
Analyze the emotional tone of the input text.
Return exactly one of: 'positive', 'negative', 'neutral'.
Consider context and sarcasm.
""";

def classify(text: str) -> str by llm;

# New feature: a one-line summary helper, specified via sem.
sem summarize = """
Summarize the input text in a single concise sentence.
Preserve the key subject and the main action; drop filler.
""";

def summarize(text: str) -> str by llm;
