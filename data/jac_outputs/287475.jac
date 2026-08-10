"""[1,2,3,4,5,6,7]"""
def reorderOddEvent(nums: list[int]) -> list[int] {
    def event(num: int) -> bool {
        return num % 2 == 0;
    }
    (left_index, right_index) = (0, len(nums) - 1);
    while left_index < right_index {
        while left_index < right_index and not event(nums[left_index]) {
            left_index += 1;
        }
        while left_index < right_index and event(nums[right_index]) {
            right_index -= 1;
        }
        if left_index < right_index {
            (nums[left_index], nums[right_index]) = (nums[right_index], nums[left_index]);
        }
    }
    return nums;
}