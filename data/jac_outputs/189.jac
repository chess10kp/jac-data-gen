"""Get value or return 'None'"""
def get_or_none(l: list[str] | str, n: int) -> str {
    try {
        return l[n];
    } except (TypeError, IndexError) {
        return 'None';
    }
}