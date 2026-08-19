import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

# Good
def translate(source_text: str, target_language: str) -> str by llm();

def detect_language(source_text: str) -> str by llm();

# Avoid
def translate_bad(t: str, l: str) -> str by llm();
