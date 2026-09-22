"""
    This method gets the affix information

    :param str text: Input text.
    """
def get_affix(text: Any) -> object {
    return " ".join([word[-4:] if (len(word) >= 4) else word for word in text.split()]);
}