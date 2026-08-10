"""
		Splits a string ever n characters -> default is 2
	"""
def asplit(string: str, number: Any = 2) -> list {
    return [string[i:(i + number)] for i in range(0, len(string), number)];
}