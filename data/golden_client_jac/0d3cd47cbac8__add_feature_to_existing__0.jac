import from byllm.lib { Model }

glob llm = Model(model_name="local:gemma-4-e4b");

enum Category { WORK, PERSONAL, HEALTH, ERRANDS, OTHER }

"""Classify a task title into one of the known categories."""
def categorize(title: str) -> Category by llm();
