"""Creates an xyz message of target location."""
def create_object_detected_msg(position: list[float]) -> dict[str, list[float]] {
    return {'coords': position};
}