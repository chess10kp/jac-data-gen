"""
	Calculates the checksum of a raw message.

	:param message: str
	:return: int
	"""
def calculateChecksum(message: str) -> int {
    return sum(ord(ch) for ch in message) % 256;
}