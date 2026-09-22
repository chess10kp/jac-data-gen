"""Return index of the closing bracket matching the first opening bracket, or -1."""
def find_match_brackets(search: str, opening: str = '<', closing: str = '>') -> int {
    index = search.find(opening);
    if index == -1 {
        return -1;
    }
    start = index + 1;
    count = 1;
    str_len = len(search);
    for index in range(start, str_len) {
        c = search[index];
        if c == opening {
            count += 1;
        } elif c == closing {
            count -= 1;
        }
        if count == 0 {
            return index;
        }
    }
    return -1;
}