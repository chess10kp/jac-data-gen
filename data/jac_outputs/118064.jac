"""Returns a string describing a class."""
def get_topic(domain_class: type) -> str {
    return domain_class.__module__ + "#" + getattr(domain_class, "__qualname__", domain_class.__name__);
}