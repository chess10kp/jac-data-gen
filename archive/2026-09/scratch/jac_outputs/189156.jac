"""Split an annotation file by sentence. Each sentence's annotation should
    be a single string."""
def split(text: Any) -> object {
    return text.strip().split('\n')[1:-1];
}