"""Search the database for matching records."""
def search_database(query: str, limit: int = 10) -> list[str] {
    # Simulated database search
    return [f"Result {i} for '{query}'" for i in range(min(limit, 3))];
}

"""Get information about a specific user."""
def get_user_info(user_id: str) -> dict {
    # Simulated user lookup
    return {
        "id": user_id,
        "name": f"User {user_id}",
        "email": f"user{user_id}@example.com"
    };
}

def query(question: str) -> str by llm(
    tools=[search_database, get_user_info]
);

with entry {
    print(query("Find records about 'machine learning'"));
    print(query("What's the email for user 42?"));
}
