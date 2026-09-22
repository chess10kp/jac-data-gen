"""Return name of failing item or None if none are failing."""
def get_failing_item(state: dict[str, bool]) -> str | None {
    for (key, value) in state.items() {
        if not value {
            return key;
        }
    }
    return None;
}