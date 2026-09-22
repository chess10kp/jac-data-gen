"""Clean up a multiline description."""
def cleanup_description(desc: str) -> str {
    return " ".join(desc.replace('\n', ' ').replace('\r', ' ').split());
}