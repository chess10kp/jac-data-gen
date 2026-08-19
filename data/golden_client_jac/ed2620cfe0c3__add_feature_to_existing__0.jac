"""Get the current date in YYYY-MM-DD format."""
def get_date() -> str { return "2026-01-01"; }

"""Search the knowledge base for the given query."""
def search_db(query: str) -> str { return query; }

"""Send an email notification to a recipient."""
def send_email(recipient: str, body: str) -> bool { return True; }

"""Look up the current weather for a city."""
def get_weather(city: str) -> str { return f"{city}: sunny"; }

def answer_question(question: str) -> str by llm(
    tools=[get_date, search_db, send_email, get_weather]
);
