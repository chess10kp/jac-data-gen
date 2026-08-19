sem analyze_code.code = "The source code to analyze";
sem analyze_code.language = "Programming language (python, javascript, etc.)";
sem analyze_code.strictness = "How strict the review should be: 'lenient', 'normal', or 'strict'";
sem analyze_code.return = "A structured analysis with issues and suggestions";

def analyze_code(code: str, language: str, strictness: str) -> dict by llm;
