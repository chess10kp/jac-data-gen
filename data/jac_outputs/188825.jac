"""Create mocking case text"""
def mocking_case(text: str) -> str {
    value = "";
    prev = "";
    for character in text {
        value += character.upper() if prev.islower() else character.lower();
        prev = value[-1:] if character.isalpha() else prev;
    }
    return value;
}