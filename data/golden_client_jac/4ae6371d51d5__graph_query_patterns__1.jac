# Per-call - highest priority
def my_agent(query: str) -> str by llm(
    tools=[search, compute],
    ctx_window=128000,
    threshold_ratio=0.75,
    keep_recent_iterations=5,
    compaction_model="ollama/llama3.2:1b",
    compaction_enabled=True,
    on_compaction=my_hook
);

# Per-object - applied to every call on this model instance
glob llm = Model(model_name="gpt-4o", ctx_window=128000);
