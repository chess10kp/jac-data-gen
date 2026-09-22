"""Return inverted binary mask from binary mask (bin_mask)."""
def invert_mask(bin_mask: str) -> str {
    inverted_mask = '';
    for char in bin_mask {
        match char {
            case "1":
                inverted_mask += '0';
            case '0':
                inverted_mask += '1';
            case _:
                inverted_mask += '.';
        }
    }
    return inverted_mask;
}