import from byllm.lib { Model }

glob llm = Model(
    model_name="custom-model",
    config={
        "api_base": "https://your-endpoint.com/v1/chat/completions",
        "api_key": "your_api_key_here",
        "http_client": True,
        "ca_bundle": True  # True (default SSL), False (skip), or "/path/to/cert.pem"
    }
);

def ask(question: str) -> str by llm();
def summarize(text: str) -> str by llm(temperature=0.2);
