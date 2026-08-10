"""
    Credits to https://stackoverflow.com/users/1235039/aquavitae
    Return a list of words and their indexes in a string.
"""
def spliter(line: str, _len: Callable[[str], int] = len) -> list[tuple[str, int, int]] {
    words = line.split(' ');
    running_offset = 0;
    offsets = [];
    for word in words {
        word_offset = line.index(word, running_offset);
        word_len = _len(word);
        running_offset = word_offset + word_len;
        offsets.append((word, word_offset, running_offset));
    }
    return offsets;
}