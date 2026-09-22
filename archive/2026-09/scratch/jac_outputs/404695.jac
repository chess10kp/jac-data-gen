"""
	This function is to remove padding.

	parameters:
		s:str
				string to be reverse padded


	"""
def revpad(s: Any) -> object {
    k = ord(s[-1]);
    temp = 0;
    for i in range(1, k) {
        if (s[-i] != s[-1]) {
            temp = 1;
        }
    }
    if (temp == 0) {
        return s[:-k];
    } else {
        return "Wrong padding";
    }
}