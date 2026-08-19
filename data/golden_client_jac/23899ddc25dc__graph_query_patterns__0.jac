"""Search the web for information."""
def search_web(query: str) -> str {
    # Simulated web search
    return f"Web results for '{query}': Found relevant information about the topic.";
}

"""Evaluate a mathematical expression."""
def calculate(expression: str) -> float {
    return float(str(eval(expression)));
}

"""Get today's date."""
def get_date() -> str {
    import datetime;
    return datetime.date.today().isoformat();
}

def research(question: str) -> str by llm(
    tools=[search_web, calculate, get_date]
);
sem research = "Answer complex questions using reasoning and tools.";

with entry {
    answer = research(
        "If today's date has an odd day number, calculate 2^10, "
        "otherwise calculate 3^5"
    );
    print(answer);
}
