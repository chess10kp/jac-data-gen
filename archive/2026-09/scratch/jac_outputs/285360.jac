def single_number(nums: list[int]) -> int {
    i = 0;
    for num in nums {
        i ^= num;
    }
    return i;
}