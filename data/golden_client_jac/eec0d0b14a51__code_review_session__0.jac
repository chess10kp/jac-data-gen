import from byllm.lib { MockLLM }

glob llm = MockLLM(
    model_name="mockllm",
    config={"outputs": ["Mocked response 1", "Mocked response 2"]}
);

def translate(text: str) -> str by llm();

test "translate returns the first mocked response" {
    assert translate("Hello") == "Mocked response 1";
}

test "translate advances to the second mocked response" {
    translate("Hello");
    assert translate("Bonjour") == "Mocked response 2";
}
