def list_sum_even(nums: list) -> int {
    total = 0;
    for n in nums {
        if n % 2 == 0 { total += n; }
    }
    return total;
}
