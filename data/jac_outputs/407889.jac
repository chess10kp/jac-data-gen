glob ASCII_UPPER_START = 0x41;
glob ASCII_UPPER_END = 0x5A;

""" Indicates if the char is upper """
def isupper(char: str) -> bool {
    len(char) == 1 and ord(char) >= ASCII_UPPER_START and ord(char) <= ASCII_UPPER_END
}