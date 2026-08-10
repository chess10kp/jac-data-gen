"""
    index_words
    :param text:
    :return:
    """
def index_words(text: str) -> list[int] {
    if not text {
        return [];
    }
    return [0] + [index + 1 for (index, letter) in enumerate(text) if letter == ' '];
}