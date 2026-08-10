"""Problem 48: Gray Code.

	Parameters
	----------
	n : int
		The number of

	Returns
	-------

	"""
def gray_code(n: int) -> list[str] {
    gray_code_list = ['0', '1'];
    if n == 1 {
        return gray_code_list;
    }
    for i in range(0, n - 1) {
        gray_code_left = [('0' + x) for x in gray_code_list];
        gray_code_list.reverse();
        gray_code_right = [('1' + x) for x in gray_code_list];
        gray_code_left.extend(gray_code_right);
        gray_code_list = gray_code_left;
    }
    return gray_code_list;
}