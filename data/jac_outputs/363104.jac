"""
    Return True if the password has at least one occurrence of three consecutive letters, e.g. abc
    or xyz, and False if it has no such ocurrences.
    """
def contains_three_consecutive_letters(password: str) -> bool {
    characters = [ord(char) for char in password];
    return `any(
        (((a + 1) == b) and ((b + 1) == c))
        for (a, b, c) in [characters[x:(x + 3)] for x in range((len(password) - 2))]
    );
}