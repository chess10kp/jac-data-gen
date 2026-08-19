obj CodeAnalysis {
    has issues: list[str];
    has suggestions: list[str];
    has complexity_score: int;
    has summary: str;
    has severity: str;
}

sem analyze.return = """
Return a CodeAnalysis object with:
- issues: List of problems found
- suggestions: Improvement recommendations
- complexity_score: 1-10 complexity rating
- summary: One paragraph overview
- severity: Overall severity, one of 'low', 'medium', 'high', 'critical'
""";

def analyze(code: str) -> CodeAnalysis by llm;
