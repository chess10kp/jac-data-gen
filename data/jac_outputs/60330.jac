"""Return a consumer id string for an agent type + host tuple.

    The logic behind this function, is that, eventually we could have
    consumers of RPC callbacks which are not agents, thus we want
    to totally collate all the different consumer types and provide
    unique consumer ids.
    """
def get_agent_consumer_id(agent_type: str, agent_host: str) -> str {
    return f"{agent_type}@{agent_host}";
}