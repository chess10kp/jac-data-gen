obj TinyResult {
    has answer: str;
}

sem TinyResult.answer = "Short answer.";
sem ask_ai = "Answer briefly in plain ASCII.";
sem ask_ai.prompt = "User prompt.";

def ask_ai(prompt: str) -> TinyResult by llm();

with entry {
    result = ask_ai("Say hello in one short sentence.");
    print(result);
}