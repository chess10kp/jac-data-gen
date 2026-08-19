import from byllm.lib { MockLLM }

glob llm = MockLLM(
    model_name="mockllm",
    config={
        "outputs": ["Mocked response 1", "Mocked response 2", "Mocked response 3"]
    }
);

def translate(text: str) -> str by llm();
def summarize(text: str) -> str by llm();
def classify(text: str) -> str by llm();

test "translate returns first mock" {
    result = translate("Hello");
    assert result == "Mocked response 1";
}

test "summarize returns second mock" {
    result = summarize("Long text...");
    assert result == "Mocked response 2";
}

test "classify returns third mock" {
    result = classify("spam?");
    assert result == "Mocked response 3";
}
