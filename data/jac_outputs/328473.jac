"""Re-encodes strings from AFIP's weird encoding to UTF-8."""
def parse_string(string: str) -> str {
    try {
        return string.encode("latin-1").decode();
    } except UnicodeDecodeError {
        return string;
    }
}