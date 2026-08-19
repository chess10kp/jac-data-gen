def sum_unique_numbers(arr: Any) -> object {
    if (len(arr) < 2) {
        return None;
    }
    unique_nums = [];
    sum = 0;
    for num in arr {
        if (num not in unique_nums) {
            unique_nums.append(num);
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_unique_numbers([-8, -4, 2]));
    print(sum_unique_numbers([-2, -1, -4, 7]));
}
