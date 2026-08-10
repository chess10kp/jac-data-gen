"""Convert a numeric list to an alphabetic string via chr/ord."""
def num_to_num(nums: list[int]) -> str {
    return ''.join([chr(i - 1 + ord('a')) for i in nums]);
}