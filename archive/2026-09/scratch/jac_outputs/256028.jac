"""Solution to exercise C-1.14.

Write a short Python function that takes a sequence of integer values and
determines if there is a distinct pair of numbers in the sequence whose
product is odd.

--------------------------------------------------------------------------
Solution:
--------------------------------------------------------------------------
The product of two odd numbers will produce an odd number.  If there are at
least two (unique) odd numbers in the sequence, the function should return
True.
"""
def odd_pair(nums: list[int]) -> bool {
    uniques = set(nums);
    odd_count = 0;
    for num in uniques {
        if num % 2 != 0 {
            odd_count += 1;
            if odd_count > 1 {
                break;
            }
        }
    }
    return odd_count > 1;
}