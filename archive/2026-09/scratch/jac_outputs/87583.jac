"""Try to make an ASCII representation of the bytes.

Non printable characters are replaced by '?' except null character which
is replaced by '.'.
"""
def format_data_ascii(data: bytes) -> str {
    msg_str = '';
    for byte in data {
        char = chr(byte);
        if char == '\0' {
            msg_str = msg_str + '.';
        } elif ord(char) < 32 or ord(char) > 126 {
            msg_str = msg_str + '?';
        } else {
            msg_str = msg_str + char;
        }
    }
    return msg_str;
}