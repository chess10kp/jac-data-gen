def translate2spanish(text: str) -> str by llm();

with entry {
    try {
        result = translate2spanish("Hello");
        print(result);
    } except Exception as e {
        print(f"AI call failed: {e}");
    }
}
