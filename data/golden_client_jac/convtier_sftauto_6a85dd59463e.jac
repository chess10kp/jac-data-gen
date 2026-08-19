def find_missing_numbers(arr: Any) -> object {
    missing_nums = `set();
    for num in arr {
        if ((num > 0) and (-num not in arr)) {
            missing_nums.add(-num);
        }
        if ((num < 0) and (`abs(num) not in arr)) {
            missing_nums.add(num);
        }
    }
    return sorted(`list(missing_nums));
}



with entry {
    print(find_missing_numbers([81]));
    print(find_missing_numbers([]));
    print(find_missing_numbers([100]));
}
