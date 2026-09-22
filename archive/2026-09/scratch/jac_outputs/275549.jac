"""
    Convert a string to title case.

    Title case means that the first letter of each word is capitalized, and all other letters in the word are lowercase.
    """
def title_case(sentence: str) -> str {
    if not isinstance(sentence, str) {
        raise TypeError(
            ('Invalid input, type %s - Input must be type string' % `type(sentence))
        );
    }
    ret = sentence[0].upper();
    for i in range(1, len(sentence)) {
        if sentence[i - 1] == ' ' {
            ret = ret + sentence[i].upper();
        } else {
            ret = ret + sentence[i].lower();
        }
    }
    return ret;
}