glob MAX_TEXT_WIDTH = 50;
glob ELLIPSIS_LEN = 3;

"""Shortens width of text."""
def shorten(text: str) -> str {
    text = text.split("\n", 1)[0];
    if len(text) > MAX_TEXT_WIDTH {
        return text[:(MAX_TEXT_WIDTH - ELLIPSIS_LEN)] + '...';
    }
    return text;
}