def running_total(nums: list) -> list {
    out = [];
    s = 0;
    for v in nums {
        out.append(s);
        s += v;
    }
    return out;
}
