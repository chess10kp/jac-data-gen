# In jac.toml - applies globally
# [plugins.byllm.compaction]
# compaction_model = "ollama/llama3.2:1b"

# Per-call
def my_agent(query: str) -> str by llm(
    tools=[search],
    compaction_model="ollama/llama3.2:1b"
);
