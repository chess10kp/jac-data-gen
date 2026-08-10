"""Convert an integer or hex integer string to an int."""
def string_to_int(num: str) -> int {
    if num.find("0x") != -1 {
        return int(num, 16);
    }
    return int(num);
}