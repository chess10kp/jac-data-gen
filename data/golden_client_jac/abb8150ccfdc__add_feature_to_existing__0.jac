obj MyClass {
    has attribute: str;
    has tone: str;

    def method_name() -> str by llm();
    def rephrase(text: str) -> str by llm();
}
