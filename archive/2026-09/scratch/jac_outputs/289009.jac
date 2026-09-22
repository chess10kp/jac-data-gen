"""Edits two given strings and compare them."""
def backspace_compare(first: str, second: str) -> bool {
    first_index = len(first) - 1;
    second_index = len(second) - 1;
    skip_in_first = 0;
    skip_in_second = 0;
    while first_index >= 0 or second_index >= 0 {
        if first[first_index] == '#' {
            skip_in_first += 1;
            first_index -= 1;
            continue;
        } elif skip_in_first > 0 {
            first_index -= 1;
            skip_in_first -= 1;
            continue;
        }
        if second[second_index] == '#' {
            skip_in_second += 1;
            second_index -= 1;
            continue;
        } elif skip_in_second > 0 {
            second_index -= 1;
            skip_in_second -= 1;
            continue;
        }
        if (first_index >= 0 and second_index < 0) or (first_index < 0 and second_index >= 0) {
            return False;
        }
        if first[first_index] != second[second_index] {
            return False;
        }
        first_index -= 1;
        second_index -= 1;
    }
    return True;
}