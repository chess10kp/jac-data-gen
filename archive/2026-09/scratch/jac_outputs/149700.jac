"""Return level change response json."""
def level_put_response_ok(devid: str, level: int) -> str {
    '{"id": "' + devid + '", "level": "' + str(level) + '"}'
}