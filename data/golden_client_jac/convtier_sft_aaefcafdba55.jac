def sign_counts(nums: list[int]) -> dict[str, int] {
    return {
        "neg": len([n for n in nums if n < 0]),
        "zero": len([n for n in nums if n == 0]),
        "pos": len([n for n in nums if n > 0])
    };
}

with entry {
    print(sign_counts([-2, 0, 3, 5]));
}
