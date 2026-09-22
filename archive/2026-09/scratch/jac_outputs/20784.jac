"""Add zero padding to number"""
def pad_number(number: Any, padding: Any = 3) -> object {
    number_string = str(number);
    padded_number = number_string.zfill(padding);
    return padded_number;
}