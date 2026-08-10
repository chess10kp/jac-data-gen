""" Check if the text has any letters in it """
def has_any_letters(text: Any) -> object {
    result = `any(c.isalpha() for c in text);
    return result;
}