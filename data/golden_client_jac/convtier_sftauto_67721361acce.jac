def sort_and_remove_duplicates(arr: Any) -> object {
    sorted_arr = sorted(arr, reverse=True);
    final_arr = [];
    for i in range((len(sorted_arr) - 1)) {
        if (sorted_arr[i] != sorted_arr[(i + 1)]) {
            final_arr.append(sorted_arr[i]);
        }
    }
    if sorted_arr {
        final_arr.append(sorted_arr[-1]);
    }
    return final_arr;
}



with entry {
    print(sort_and_remove_duplicates('hello'));
    print(sort_and_remove_duplicates('Racecar'));
    print(sort_and_remove_duplicates('abcabc'));
}
