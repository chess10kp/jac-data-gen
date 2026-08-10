""" It formats titles extracted from the scraped HTML code.
    """
def formatTitle(title: str) -> str {
    if len(title) > 40 {
        return title[:40] + "...";
    }
    return title;
}