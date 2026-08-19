# High temperature -> creative, varied prose
def write_story(topic: str) -> str by llm(temperature=0.9);
sem write_story = "Write a short, imaginative story about the given topic.";

# Zero temperature -> deterministic, faithful extraction
def extract_facts(text: str) -> str by llm(temperature=0.0);
sem extract_facts = "Extract only facts explicitly stated in the text. Do not infer or embellish.";
