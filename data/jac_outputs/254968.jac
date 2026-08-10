"""Conservatively assume minimum 5 seconds or 3 seconds per 1MB."""
def _get_timeout_ms(timeout: float | None, payload_size: int | float) -> int {
    if timeout is not None {
        return int(1000 * timeout);
    }
    return int(1000 * max(3 * payload_size / 1024 / 1024, 5));
}