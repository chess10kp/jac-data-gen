"""Returns true if any of the keys of message start with prefix."""
def messages_contains_prefix(prefix: str, messages: dict[str, object]) -> bool {
    return any(x.startswith(prefix) for x in messages.keys());
}