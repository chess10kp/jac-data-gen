"""Convert a string to title case.

Title case means that the first character of every word is capitalized
and all the rest are lowercase.
"""
def title_case(sentence: str) -> str {
    if not isinstance(sentence, str) {
        raise TypeError("Input sentence must be type str");
    }
    if len(sentence) == 0 {
        raise ValueError("Input sentence cannot be empty");
    }
    return sentence.title();
}