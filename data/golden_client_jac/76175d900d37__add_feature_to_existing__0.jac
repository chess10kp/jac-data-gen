import from byllm.lib { ConfigurationError, Model }

glob llm = Model(model_name="gpt-4o");

obj Product {
    has name: str;
    has price: float;
}

# Structured output: NO streaming.
def get_product(prompt: str) -> Product by llm();

# Streaming works here because it returns str.
def describe_product(prompt: str) -> str by llm(stream=True);
