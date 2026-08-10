"""Returns the longest palindrome starting at the beginning of s"""
def longest_initial_palindrome(s: str) -> str {
    start = 0;
    end = len(s) - 1;
    end_of_initial_run = 0;
    while start < end {
        if s[start] == s[end] {
            start += 1;
            if start - 1 == end_of_initial_run and s[start] == s[0] {
                end_of_initial_run = start;
            }
        } elif not (start - 1 == end_of_initial_run and s[end] == s[0]) {
            start = end_of_initial_run = 0;
        }
        end -= 1;
    }
    return s[:(start + end + 1)];
}