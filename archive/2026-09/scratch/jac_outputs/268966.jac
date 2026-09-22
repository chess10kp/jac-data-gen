"""Map each one-character substring to its occurrence count."""
def str_to_c2count(string: str) -> dict[str, int] {
    count: dict[str, int] = {};
    for character in string {
        if character in count {
            count[character] += 1;
        } else {
            count[character] = 1;
        }
    }
    return count;
}