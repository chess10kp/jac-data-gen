"""
    Converts the fully qualified name of a topic into legal mongodb collection name.
    """
def topic_name_to_collection_name(topic_name: str) -> str {
    topic_name.replace("/", "_")[1:]
}