def count_pairs_divisible_by_3(nums: Any) -> object {
    count = 0;
    remainder_count = [0, 0, 0];
    for num in nums {
        remainder = num % 3;
        remainder_count[remainder] += 1;
    }
    count += (remainder_count[0] * (remainder_count[0] - 1)) // 2;
    count += remainder_count[1] * remainder_count[2];
    return count;
}



with entry {
    print(count_pairs_divisible_by_3([]));
}
