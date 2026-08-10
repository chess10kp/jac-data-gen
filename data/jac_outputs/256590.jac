"""Checks if the citation contains a doi."""
def citationContainsDOI(citation: str) -> bool {
    return citation.startswith(("doi:", "@doi:", "[@doi"));
}