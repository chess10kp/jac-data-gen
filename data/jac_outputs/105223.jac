"""Wrap regex to require non-alphanumeric characters on left and right."""
def nonalphanum_boundaries_re(regex: str) -> str {
    return rf"(?:^|[^a-zA-Z0-9])({regex})(?:[^a-zA-Z0-9]|$)";
}