"""Given a list, check if it is equal to a sorted list containing 1-9."""
def check_unique_list(input: list[int | str]) -> bool {
    int_list = list(map(int, input));
    int_list.sort();
    return int_list == [1, 2, 3, 4, 5, 6, 7, 8, 9];
}