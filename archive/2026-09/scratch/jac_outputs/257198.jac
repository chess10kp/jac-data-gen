""" assumes s a string
        Returns an int that is the sum of all of the digits in s.
          If there are no digits in s it raises a ValueError exception.
          For example, sum_digits("a;35d4") returns 12. """
def sum_digits(s: str) -> int {
    ans = 0;
    value_error_cnt = 0;
    for element in s {
        try {
            ans += int(element);
        } except ValueError {
            value_error_cnt += 1;
            if value_error_cnt == len(s) {
                raise ValueError();
            } else {
                continue;
            }
        }
    }
    return ans;
}