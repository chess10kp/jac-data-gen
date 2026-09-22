"""Helper method to remove any namespaces from the XML tag"""
def _short_tag(tag: str) -> str {
    tag[tag.rfind('}') + 1:]
}