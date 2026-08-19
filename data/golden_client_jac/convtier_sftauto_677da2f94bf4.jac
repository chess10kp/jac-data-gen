def find_single_element(arr: Any) -> object {
    result = 0;
    for num in arr {
        result ^= num;
    }
    return arr.index(result);
}



with entry {
    print(find_single_element([2]));
    print(find_single_element([2, 4, 6, 8]));
    print(find_single_element([4, 2, 7, 1, 9]));
}
