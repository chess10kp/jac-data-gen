def remove_divisible_elements(arr: Any) -> object {
    filtered_arr = [
        x
        for x in arr
        if ((x <= 10) or ((x % 5) != 0))
    ];
    filtered_arr.sort(reverse=True);
    return filtered_arr;
}



with entry {
    print(remove_divisible_elements([2, 7]));
    print(remove_divisible_elements([2]));
    print(remove_divisible_elements([34]));
}
