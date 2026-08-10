"""Return the Kth paragraph from PARAGRAPHS for which SELECT called on the paragraph returns true."""
def choose(paragraphs: list[str], select: callable, k: int) -> str {
    result = [p for p in paragraphs if select(p)];
    if len(result) >= k + 1 {
        return result[k];
    }
    return '';
}