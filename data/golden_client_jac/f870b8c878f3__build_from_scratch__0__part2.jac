def min_list(nums: list) -> int {
    m = nums[0];
    for v in nums {
        if v < m {
            m = v;
        }
    }
    return m;
}

with entry {
    print(min_list([3, 1, 4, 1, 5, 9, 2, 6]));
    print(min_list([10, 20, 5]));
    print(min_list([-3, -1, -7]));
    print(min_list([42]));
    print(min_list([0, 0, 0]));
}
