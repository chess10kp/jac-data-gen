"""generate aligned row"""
def create_row(*fields: tuple[str, int, int, str]) -> str {
    row = "";
    for field in fields {
        (value, width, padding, alignment) = field;
        value = value[:(width - padding)] + ".."
            if len(value) > width - padding
            else value;
        if alignment == 'right' {
            row += value + (width - len(value)) * ' ';
        } else {
            row += (width - len(value) - padding) * ' ' + value + padding * ' ';
        }
    }
    return row;
}