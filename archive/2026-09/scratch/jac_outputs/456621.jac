"""
	:param n: int, an integer number
	:param big: the current largest digit
	:return: int, the final largest digit
	"""
def helper(n: Any, big: Any) -> object {
    n = abs(n);
    if (n == 0) {
        return big;
    } else {
        if (big < int((n % 10))) {
            big = int((n % 10));
        }
        return helper((n / 10), big);
    }
}