"""Returns an awesome string."""
def source_page(is_awesome: bool) -> str {
    if is_awesome {
        return f"{is_awesome}! SourcePage is awesome!";
    }
    return f"{is_awesome}! Nah, SourcePage is still awesome!";
}