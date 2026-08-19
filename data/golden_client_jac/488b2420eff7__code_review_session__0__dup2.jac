def write_story(topic: str) -> str by llm(temperature=0.9);

sem write_story = "Write a short, engaging creative story about the given topic.";
sem write_story.topic = "The subject the story should be about.";

def extract_facts(text: str) -> str by llm(temperature=0.0);

sem extract_facts = "Extract the key factual statements from the given text, one per line.";
sem extract_facts.text = "The source text to extract facts from.";
