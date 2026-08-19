def max_in_list(nums: list) -> int {
    m = nums[0];
    for n in nums {
        if n > m {
            m = n;
        }
    }
    return m;
}

with entry {
    for x in [[3, 1, 4, 1, 5], [-2, -9, -1], [42], [7, 7, 7]] {
        print(max_in_list(x));
    }
}
