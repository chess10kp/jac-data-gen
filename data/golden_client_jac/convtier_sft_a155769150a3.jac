def run_lengths(nums: list[int]) -> list[tuple[int, int]] {
    out: list[tuple[int, int]] = [];
    for n in nums {
        if out and out[-1][0] == n {
            out[-1] = (n, out[-1][1] + 1);
        } else {
            out.append((n, 1));
        }
    }
    return out;
}

with entry {
    print(run_lengths([1, 1, 2, 3, 3, 3]));
}
