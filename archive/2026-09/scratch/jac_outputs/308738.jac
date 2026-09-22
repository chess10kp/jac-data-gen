"""write a program which takes as input an array of digits encoding a non negative
       decimal integer D and updates the array to represent D+1. For example (1,2,9)->(1,3,0)

    Args:
        nums (array): [array of integer]
    """
def plus_one(nums: list[int]) -> list[int] {
    nums[-1] += 1;
    n = len(nums);
    for i in range(n - 1, -1, -1) {
        if nums[i] != 10 {
            break;
        }
        nums[i] = 0;
        nums[i - 1] += 1;
    }
    if nums[0] == 10 {
        nums[0] = 1;
        nums.append(0);
    }
    return nums;
}