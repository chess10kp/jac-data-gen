def list_sum_even(nums: list) -> int {
    return sum([n for n in nums if n % 2 == 0]);
}

with entry {
    for x in [[1, 2, 3, 4, 5, 6], [10, 15, 20, 25], [1, 3, 5], []] {
        print(list_sum_even(x));
    }
}
