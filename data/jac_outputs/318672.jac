"""
        Try to convert intstr to an int; if it fails, return None instead of ValueError like int()
    """
def _softint(intstr: str | bytes, base: int = 10) -> int | None {
    try {
        return int(intstr, base);
    } except ValueError {
        return None;
    }
}