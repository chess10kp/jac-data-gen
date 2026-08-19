def my_compactor(messages: list, keep_recent: int) -> list {
    # messages[0] = system, messages[1] = original user task - always preserve
    # messages[2:] = tool-call history to summarise
    summary = my_domain_summariser(messages[2:]);
    summary_msg = {"role": "user", "content": f"[Summary] {summary}"};
    return [messages[0], messages[1], summary_msg] + messages[-keep_recent * 2:];
}

def my_agent(query: str) -> str by llm(
    tools=[search],
    on_compaction=my_compactor
);
