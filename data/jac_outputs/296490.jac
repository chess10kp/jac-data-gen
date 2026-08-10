"""
    Get a list of issue types.

    :rtype: list
    """
def determine_issue_types(warnings: Any) -> object {
    issue_types = warnings["Report"]["IssueTypes"]["IssueType"];
    if not isinstance(issue_types, list) {
        return [issue_types];
    }
    return issue_types;
}