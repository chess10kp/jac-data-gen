import from byllm.lib { MockLLM }

glob llm = MockLLM(
    model_name="mockllm",
    config={
        "outputs": ["Mocked response 1", "Mocked response 2"]
    }
);

def translate(text: str) -> str by llm();

def summarize(text: str) -> str by llm();

test "translate" {
    result = translate("Hello");
    assert result == "Mocked response 1";
}

test "summarize" {
    result = summarize("A long piece of text");
    assert result == "Mocked response 2";
}
