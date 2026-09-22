"""Front pad a string with a certain char if it isn't already at least a given length long."""
def front_pad_string(string: object, length: int = 2, char: str = "0") -> str {
    string = str(string);
    while len(string) < length {
        string = char + string;
    }
    return string;
}