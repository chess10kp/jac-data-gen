"""Solution to exercise C-4.17.

    Write a short recursive Python function that determines if a string s is a
    palindrome, that is, it is equal to its reverse. For example, "racecar"
    and "gohangasalamiimalasagnahog" are palindromes.
    """
def is_palindrome(string: str) -> bool {
    n = len(string);
    def recurse(idx: int) -> bool {
        if idx == n {
            return True;
        }
        if string[idx] == string[n - 1 - idx] {
            return recurse(idx + 1);
        }
        return False;
    }
    return recurse(0);
}