"""Convert subscripts/superscripts, symbols, etc to characters."""
def clean_symbols(in_text: str) -> str {
    if '\u00B2' in str(in_text) {
        return in_text.replace('\u00B2', '2');
    } elif '\u00B3' in str(in_text) {
        return in_text.replace('\u00B3', '3');
    } elif '\u00B0' in str(in_text) {
        return in_text.replace('\u00B0', 'Degrees');
    }
    return in_text;
}