"""
Brute force solution
Don't preserve order
"""
def removeElement_1(nums: list[int], val: int) -> int {
    val_freq = 0;
    for num in nums {
        if num == val {
            val_freq += 1;
        }
    }
    new_len = len(nums) - val_freq;
    i = 0;
    j = len(nums) - 1;
    while val_freq > 0 and i < new_len {
        if nums[i] == val {
            print('index:', i);
            while j > 0 and nums[j] == val {
                j -= 1;
            }
            print('j:', j);
            temp = nums[i];
            nums[i] = nums[j];
            nums[j] = temp;
            val_freq -= 1;
            j -= 1;
        }
        i += 1;
    }
    return new_len;
}