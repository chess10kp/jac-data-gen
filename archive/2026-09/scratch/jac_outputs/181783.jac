"""A palindromic number reads the same both ways. such as 9009"""
def isPalindromic(n: int) -> bool {
    s = str(n);
    return s == s[::-1];
}