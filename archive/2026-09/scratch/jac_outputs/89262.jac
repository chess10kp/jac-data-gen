"""Determine the category of an issue."""
def determine_issue_category(issue_type: Any, issue_types: Any) -> object {
    category = None;
    for issue in issue_types {
        issue_id = issue["@Id"];
        if (issue_id == issue_type) {
            category = issue["@Category"];
            break;
        }
    }
    return category;
}