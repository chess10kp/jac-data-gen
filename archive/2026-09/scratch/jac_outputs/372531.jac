"""Get first element of list or return default."""
def getitem(`obj: list[object], key: int = 0, `default: object | None = None) -> object | None {
    try {
        return `obj[key];
    } except Exception {
        return `default;
    }
}