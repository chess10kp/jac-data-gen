"""RL driver (synthetic): minimum value of a non-empty list of integers."""

def min_list(nums: list) -> int;

impl min_list {
    # >>>HOLE id="syn_min_list" instruction="Implement min_list(nums): return the smallest value in the non-empty list nums. Start with the first element as the current minimum, then scan the list and replace it whenever a smaller value is found."
    m = nums[0];
    for v in nums {
        if v < m {
            m = v;
        }
    }
    return m;
    # <<<HOLE
}

with entry {
    print(min_list([3, 1, 4, 1, 5, 9, 2, 6]));
    print(min_list([10, 20, 5]));
    print(min_list([-3, -1, -7]));
    print(min_list([42]));
    print(min_list([0, 0, 0]));
}
