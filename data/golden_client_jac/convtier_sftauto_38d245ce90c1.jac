def separate_odd_numbers(arr: Any) -> object {
    odd_arr = [];
    for num in arr {
        if (
            isinstance(num, int)
            and ((num % 2) != 0)
            and (num > 0)
            and (num not in odd_arr)
        ) {
            odd_arr.append(num);
        }
    }
    odd_arr.sort();
    return odd_arr;
}



with entry {
    print(separate_odd_numbers('hello'));
}
