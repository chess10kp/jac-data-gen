"""Create an underline string of a certain length."""
def set_underline(level: int, length: int) -> str {
    underline_symbol = ["`", "#", "*", "-", "^", '"', "="];
    symbol_str = underline_symbol[level] * length;
    f"\n{symbol_str}\n"
}