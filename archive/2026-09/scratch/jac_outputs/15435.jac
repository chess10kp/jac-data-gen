"""Return True if given string is a panagram."""
def is_pangram(sentence: str) -> bool {
    sentence = sentence.lower();
    alphabet = 'abcdefghijklmnopqrstuvwxyz';
    return set(sentence).issuperset(alphabet);
}