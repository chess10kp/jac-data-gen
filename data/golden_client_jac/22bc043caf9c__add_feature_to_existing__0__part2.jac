"""Fallback model pool for resilient LLM calls."""

import from byllm.lib { Model, ModelPool }

glob llm = ModelPool(
    models=[
        Model(model_name="gpt-4o"),
        Model(model_name="gpt-4o-mini")
    ],
    strategy="fallback"
);

def answer(question: str) -> str by llm();

# New feature: a second pooled helper that classifies intent, reusing the pool.
def classify_intent(question: str) -> str by llm();
sem classify_intent = "Classify the user's intent as one of: question, command, chit_chat.";
