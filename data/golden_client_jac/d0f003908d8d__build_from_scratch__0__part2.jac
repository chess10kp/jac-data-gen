def running_total(nums: list) -> list {
    out = [];
    s = 0;
    for v in nums {
        s += v;
        out.append(s);
    }
    return out;
}

with entry {
    print(running_total([1, 2, 3, 4]));
    print(running_total([5, 5, 5]));
    print(running_total([-1, 1, -1, 1]));
    print(running_total([10]));
    print(running_total([0, 0, 0]));
}
