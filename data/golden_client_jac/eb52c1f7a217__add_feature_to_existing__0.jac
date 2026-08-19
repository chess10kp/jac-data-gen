obj Article {
    has title: str;
    has content: str;
    has author: str;
    has language: str;

    def generate_summary() -> str by llm();
    def suggest_tags() -> list[str] by llm();
    def translate_title(target_language: str) -> str by llm();
}
