"""Get a queue name for a given topic and host."""
def queue_get_for(topic: str, host: str) -> str {
    return f"{topic}.{host}" if host else topic;
}