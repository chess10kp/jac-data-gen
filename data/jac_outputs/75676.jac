"""Return a list of unique elements of an array."""
def unique_elements(array: list[int]) -> list[int] {
    unique = [];
    for x in array {
        if x not in unique {
            unique.append(x);
        }
    }
    return unique;
}