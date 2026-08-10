"""
    Convert from HTML tags to JIRA markdown
    :param html_tag:
    :return:
    """
def get_jira_tag(html_tag: str) -> str {
    html_to_jira_tags = {'ol': '#', 'ul': '*', 'li': ''};
    if html_tag not in html_to_jira_tags {
        return '';
    }
    return html_to_jira_tags[html_tag];
}