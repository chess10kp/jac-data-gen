def twoSum(nums: list[int], target: int) -> list[int] | None {
    htbl = {};
    for (i, num) in enumerate(nums) {
        t = target - num;
        if t in htbl {
            return [htbl[t], i];
        }
        htbl[num] = i;
    }
    return None;
}