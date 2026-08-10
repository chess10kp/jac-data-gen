"""Utility method for parsing JIRA comments represented as JSON."""
def extract_comments(comments: list[dict[str, str]]) -> str {
    additional_notes = "";
    for comment in comments {
        additional_notes = additional_notes + comment['body'] + "\n";
    }
    return additional_notes;
}