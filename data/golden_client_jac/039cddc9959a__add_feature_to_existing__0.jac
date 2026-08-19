import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

def generate_summary(text: str) -> str by llm();

# New LLM-powered function added
def translate(text: str, target_language: str) -> str by llm();

# New: sentiment classification into a fixed label
def classify_sentiment(text: str) -> str by llm();
