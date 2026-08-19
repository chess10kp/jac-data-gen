def sum_list(nums: list[int]) -> int {
    total = 0;
    for n in nums { total += n; }
    return total;
}

with entry {
    print(sum_list([1, 2, 3, 4, 5]));
}
