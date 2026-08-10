"""Return a tuple of stripped codes split by ','."""
def _stripped_codes(codes: str) -> tuple[str, ...] {
    return tuple(
        code.strip() for code in codes.split(',') if code.strip()
    );
}