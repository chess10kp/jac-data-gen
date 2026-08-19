def product(nums: list[int]) -> int {
    result = 1;
    for n in nums { result *= n; }
    return result;
}

with entry {
    print(product([1, 2, 3, 4]));
}
