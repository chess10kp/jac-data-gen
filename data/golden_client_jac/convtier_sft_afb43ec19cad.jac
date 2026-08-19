def moving_avg(nums: list[float]) -> list[float] {
    return [round(sum(nums[i:i + 3]) / 3, 2) for i in range(len(nums) - 2)];
}

with entry {
    print(moving_avg([1.0, 2.0, 3.0, 4.0]));
}
