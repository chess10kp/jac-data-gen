def clamp_scores(nums: list[int]) -> list[int] {
    return [0 if n < 0 else (100 if n > 100 else n) for n in nums];
}

with entry {
    print(clamp_scores([-5, 42, 130]));
}
