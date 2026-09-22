"""Find two indices whose values sum to target."""
def twoSum(nums: list[int], target: int) -> list[int] | None {
    index_map: dict[int, int] = {};
    for (i, num) in enumerate(nums) {
        pair = target - num;
        if pair in index_map {
            return [index_map[pair], i];
        }
        index_map[num] = i;
    }
    return None;
}