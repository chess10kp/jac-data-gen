"""RL driver (synthetic): find the maximum value in a non-empty list."""

def max_in_list(nums: list) -> int;

impl max_in_list {
    # >>>HOLE id="syn_max_in_list" instruction="Implement max_in_list(nums): return the largest integer in nums. Assume nums is non-empty. Iterate and track the running maximum starting from the first element."
    m = nums[0];
    for n in nums {
        if n > m {
            m = n;
        }
    }
    return m;
    # <<<HOLE
}

with entry {
    for x in [[3, 1, 4, 1, 5], [-2, -9, -1], [42], [7, 7, 7]] {
        print(max_in_list(x));
    }
}
