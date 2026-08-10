"""Remove trailing linebreak."""
def remove_all_linebreaks(comment: str) -> str {
    return comment.replace("\n", "");
}