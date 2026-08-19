def classify(text: str) -> str by llm();

test "classify returns third mock" {
    result = classify("spam?");
    assert result == "Mocked response 3";
}
