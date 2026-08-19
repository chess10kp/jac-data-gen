def find_second_highest_odd(arr: Any) -> object {
    if (len(arr) < 2) {
        return -1;
    }
    return find_second_highest_odd_recursive(arr, -1, -1);
}



with entry {
    print(find_second_highest_odd([2]));
}
