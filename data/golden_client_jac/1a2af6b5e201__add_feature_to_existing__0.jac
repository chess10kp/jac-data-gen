def search(query: str) -> str { return query; }

# Per-call
def my_agent(query: str) -> str by llm(
    tools=[search],
    compaction_model="ollama/llama3.2:1b",
    compaction_enabled=True,
    threshold_ratio=0.8
);
