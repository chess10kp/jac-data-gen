"""Spin words greater than five char long in a string.

    preserving white spaces."""
def spin_words(sentence: str) -> str {
    words = sentence.split();
    spun = [word[::-1] if len(word) >= 5 else word for word in words];
    return ' '.join(spun);
}