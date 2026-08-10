"""Return True if a given word or phrase is an isogram."""
def is_isogram(string: str) -> bool {
    letters = [
        letter
        for letter in string.casefold()
        if letter.isalpha()
    ];
    return len(letters) == len(set(letters));
}