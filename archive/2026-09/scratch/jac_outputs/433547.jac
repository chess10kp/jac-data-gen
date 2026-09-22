"""Return arithmetic mean of nums : (a1 + a2 + ... + an)/n"""
def _arithmetic_mean(nums: list[float]) -> float {
    return sum(nums) / len(nums);
}