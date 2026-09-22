"""
    Check whether just some words in the input are ALL CAPS.
    """
def allcap_differential(words: list[str]) -> bool {
    allcap_words = sum(1 for word in words if word.isupper());
    return allcap_words > 0 and allcap_words < len(words);
}