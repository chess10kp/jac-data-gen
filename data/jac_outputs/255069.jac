"""Part of the coincidence index of a message`s columns: the letters count process"""
def count_occurences(column: str) -> dict[str, int] {
    letters_count = {c: 0 for c in column};
    for c in column {
        letters_count[c] += 1;
    }
    return letters_count;
}