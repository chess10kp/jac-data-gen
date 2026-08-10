"""Add leading zeros until the string reaches out_len characters."""
def add_leading_zeros(input_string: str, out_len: int) -> str {
    input_string.zfill(out_len)
}