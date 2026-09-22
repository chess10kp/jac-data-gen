"""Constructs a cache key using a fixed separator."""
def make_cache_key(question: str, docid: str) -> str {
    return question + '###' + docid;
}