def translate(text: str, target_language: str) -> str by llm();
sem translate = "Translate the given text into the target language, preserving tone.";

def detect_language(text: str) -> str by llm();
sem detect_language = "Detect the language of the given text and return its English name.";
