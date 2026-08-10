"""
	Make the standard-format id (3- or 5-letter alpha code, followed by 7-digit number).

	Parameters
	----------
	letter_code : str
		3-character code (e.g. USA, BRA, CHN) or 5-character source code.
	id_number : int
		Number less than 10-million.

	Returns
	-------
	idnr : unicode
		Alpha code followed by zero-leading 7-character numeral.

	"""
def make_id(letter_code: Any, id_number: Any) -> object {
    return "{alpha}{num:07d}".format(alpha=letter_code, num=id_number);
}