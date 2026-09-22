"""
Converts a string with hex bytes to a numeric value
Arguments:
input_str - A string representing the bytes to convert. Example : 41414141
Return:
the numeric value
"""
def hex_str_to_int(input_str: str) -> int {
    try {
        val_to_return = int(input_str, 16);
    } except Exception as e {
        val_to_return = 0;
        print(e);
    }
    return val_to_return;
}