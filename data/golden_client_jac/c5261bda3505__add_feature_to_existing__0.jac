def my_domain_summariser(messages: list) -> str {
    return "domain-specific summary";
}

def search(query: str) -> str { return query; }

def my_compactor(messages: list, keep_recent: int) -> list {
    # messages[0] = system, messages[1] = original user task - always preserve
    summary = my_domain_summariser(messages[2:]);
    summary_msg = {"role": "user", "content": f"[Summary] {summary}"};
    return [messages[0], messages[1], summary_msg] + messages[-keep_recent * 2:];
}

def my_agent(query: str) -> str by llm(
    tools=[search],
    on_compaction=my_compactor
);

def research_agent(topic: str) -> str by llm(
    tools=[search],
    on_compaction=my_compactor,
    keep_recent_iterations=3
);
