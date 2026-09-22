"""Constructs a full description for the rule."""
def get_help(
    format: str,
    tool_name: str,
    rule_id: str,
    test_name: str,
    issue_dict: dict[str, str]
) -> str {
    issue_text = issue_dict.get("issue_text", "");
    if format == "text" {
        issue_text = issue_text.replace("`", "");
    }
    return issue_text;
}