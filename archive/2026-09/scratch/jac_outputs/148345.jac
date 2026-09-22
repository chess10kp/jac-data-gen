"""Move operation.

    move position X to position Y means that the letter which is at
    index X should be removed from the string, then inserted such that it
    ends up at index Y.
    """
def move(text: str, i: int, j: int) -> str {
    chars = [t for t in text];
    letter = chars[i];
    chars.pop(i);
    chars.insert(j, letter);
    return "".join(chars);
}