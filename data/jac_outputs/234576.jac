"""Parse through a snippet of text that states what the values are in."""
def find_sigfigs(text: str) -> str {
    text = text.lower();
    if 'million' in text {
        return 'million';
    } elif 'thousand' in text {
        return 'thousand';
    } elif 'billion' in text {
        return 'billion';
    }
    return 'unknown';
}