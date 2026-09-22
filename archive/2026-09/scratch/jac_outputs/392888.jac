"""Convert an octal string to an int, respecting None."""
def octal_to_int(oct_str: str | None) -> int | None {
    return int(oct_str, 8) if oct_str else None;
}