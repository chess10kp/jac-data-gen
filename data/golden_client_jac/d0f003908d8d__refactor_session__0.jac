"""RL driver (synthetic): running (cumulative) totals of a list of integers."""

def running_total(nums: list) -> list;

impl running_total {
    # >>>HOLE id="syn_running_total" instruction="Implement running_total(nums): return a new list whose i-th element is the sum of nums[0..i] inclusive (the cumulative sum). Keep a running sum starting at 0, add each value in order, and append the running sum after each addition."
    out = [];
    s = 0;
    for v in nums {
        s += v;
        out.append(s);
    }
    return out;
    # <<<HOLE
}

with entry {
    print(running_total([1, 2, 3, 4]));
    print(running_total([5, 5, 5]));
    print(running_total([-1, 1, -1, 1]));
    print(running_total([10]));
    print(running_total([0, 0, 0]));
}
