"""Render a pagination block with appropriate links, based on the given Django Page object."""
def paginate(page: dict[str, str]) -> dict[str, dict[str, str]] {
    context = {'page': page};
    return context;
}