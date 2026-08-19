def my_agent(query: str) -> str by llm(
        tools=[search, fetch, analyze],
        parallelize=True
    );
