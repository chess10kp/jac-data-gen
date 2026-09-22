"""Convert string of digits to string of hex."""
def _digit_to_hex(string_of_digit: Any) -> object {
    return "".join(
        [
            hex(int(i))[2:]
            for i in [
                string_of_digit[i:(i + 2)] for i in range(0, len(string_of_digit), 2)
            ]
        ]
    );
}