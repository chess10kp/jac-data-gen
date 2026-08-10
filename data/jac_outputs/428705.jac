"""Convert input string message into an integer."""
def stringToInt(message: str) -> int {
    string_to_binary = message.encode('utf8');
    return int.from_bytes(string_to_binary, byteorder='big', signed=False);
}