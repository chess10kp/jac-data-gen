def sum_even(nums: list[int]) -> int {
    return sum([n for n in nums if n % 2 == 0]);
}

with entry {
    print(sum_even([1, 2, 3, 4, 5, 6]));
}
