"""Get query parameter of a URL."""
def get_query(string: str, pos: int = 1) -> str {
    try {
        return string.split("?")[pos];
    } except IndexError {
        if pos == 1 {
            return "";
        } else {
            return string;
        }
    }
}