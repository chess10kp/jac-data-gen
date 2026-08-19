"""Model-scoped LLM helpers."""

import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

def summarize(text: str) -> str by llm();   # uses gpt-4o here only

# New feature: extract keywords with a cheaper model, leaving summarize on gpt-4o.
glob keyword_model = Model(model_name="gpt-4o-mini");

def extract_keywords(text: str) -> list[str] by keyword_model();
sem extract_keywords = "Return the 3-5 most important keywords from the text.";
