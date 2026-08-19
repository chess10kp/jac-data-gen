"""Cross-provider fallback pool."""

import from byllm.lib { Model, ModelPool }

glob llm = ModelPool(
    models=[
        Model(model_name="gemini/gemini-2.5-flash"),    # try first
        Model(model_name="gpt-4o-mini"),                 # if gemini fails
        Model(model_name="claude-sonnet-4-20250514"),    # last resort
    ],
    strategy="fallback",
);

def answer(question: str) -> str by llm();

# New feature: a summarize helper sharing the same resilient pool.
def summarize(text: str) -> str by llm();
sem summarize = "Summarize the input into two or three sentences.";
