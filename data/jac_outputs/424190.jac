"""Remove certain characters from a string."""
def convert_string(string: str, chars: list[str] | None = None) -> str {
    if chars is None {
        chars = [',', '.', '-', '/', ':', '  '];
    }
    for ch in chars {
        if ch in string {
            string = string.replace(ch, ' ');
        }
    }
    return string;
}