def find_max_difference(arr: Any) -> object {
    min_num = arr[0];
    max_num = arr[0];
    for num in arr {
        if (num < min_num) {
            min_num = num;
        }
        if (num > max_num) {
            max_num = num;
        }
    }
    max_diff = max_num - min_num;
    return max_diff;
}



with entry {
    print(find_max_difference([4, 2, 1]));
    print(find_max_difference([2, 1]));
    print(find_max_difference([5, 5, 5]));
}
