"""Generate a string search key for a Jira issues."""
def key_for_issues(issue: dict[str, str]) -> str {
    return ' '.join([issue['key'], issue['summary']]);
}