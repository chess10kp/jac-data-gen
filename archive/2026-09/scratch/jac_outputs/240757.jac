"""Tries to turn input into an integer. If that fails, returns input without conversion."""
def _tryint_(s: object) -> object {
    try {
        return int(s);
    } except ValueError {
        return s;
    }
}