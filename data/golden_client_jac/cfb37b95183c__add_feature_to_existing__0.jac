import from byllm.lib { Model }

glob llm = Model(
    model_name="gpt-4o",
    api_key="your_litellm_virtual_key",
    config={"api_base": "http://localhost:8000"}
);

glob cheap_llm = Model(
    model_name="gpt-4o-mini",
    api_key="your_litellm_virtual_key",
    config={"api_base": "http://localhost:8000", "temperature": 0.2}
);

def deep_answer(question: str) -> str by llm();
def quick_answer(question: str) -> str by cheap_llm();
