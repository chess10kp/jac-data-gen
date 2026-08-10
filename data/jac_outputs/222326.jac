""""Function to return a dictionary of alphabet as keys
        and their count's as values from a list of alphabets"""
def count(string: list[str]) -> dict[str, int] {
    unique = dict();
    for elem in string {
        if elem in unique {
            unique[elem] = unique[elem] + 1;
        } else {
            unique[elem] = 1;
        }
    }
    return unique;
}