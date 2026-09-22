"""Returns the most frequently occurring items in the given list, nums"""
def modes(nums: list[int]) -> list[int] {
    if len(nums) == 0 {
        return [];
    }
    frequencies: dict[int, int] = {};
    for num in nums {
        frequencies[num] = 1 + frequencies.get(num, 0);
    }
    max_occurrences = max(frequencies.values());
    return [num for (num, frequency) in frequencies.items() if frequency == max_occurrences];
}