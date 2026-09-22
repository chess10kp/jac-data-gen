"""Returns a column containing markdown link to show on dashboard."""
def _CreateLinkColumn(name: str, label: str, url: str) -> dict[str, str] {
    return {('a_' + name): ('[%s](%s)' % (label, url))};
}