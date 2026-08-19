glob llm = ModelPool(models=[Model(model_name="gpt-4o"), Model(model_name="gpt-4o-mini")], strategy="fallback");
def classify_intent(question: str) -> str by llm();
