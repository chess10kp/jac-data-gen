"""Search for a doi in a list of references."""
def is_in_references(references: list[str], doi: str) -> bool {
    url_doi = doi.replace('/', '%2F');
    return any(url_doi in reference or doi in reference for reference in references);
}