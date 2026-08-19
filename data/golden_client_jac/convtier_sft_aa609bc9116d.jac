def dedupe(nums: list[int]) -> list[int] {
    seen: set = set();
    out: list[int] = [];
    for n in nums {
        if n not in seen {
            seen.add(n);
            out.append(n);
        }
    }
    return out;
}

with entry {
    print(dedupe([1, 2, 2, 3, 1]));
}
