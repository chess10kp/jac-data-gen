"""Helper function to build quarter name for JIRA."""
def build_quarter_string(operational_year: str, operational_quarter: str) -> str {
    'Y%s-Q%s' % (operational_year, operational_quarter)
}