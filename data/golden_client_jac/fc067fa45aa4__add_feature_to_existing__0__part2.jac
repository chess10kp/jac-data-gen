"""Custom-endpoint model exposed through an HTTP endpoint."""

import from byllm.lib { Model }

glob llm = Model(
    model_name="gpt-4o",
    config={
        "base_url": "https://your-endpoint.com/v1",
        "proxy": True
    }
);

def answer(question: str) -> str by llm();

# New feature: expose the LLM as a public server endpoint.
def:pub ask(question: str) -> dict[str, str] {
    reply = answer(question);
    return {"question": question, "answer": reply};
}
