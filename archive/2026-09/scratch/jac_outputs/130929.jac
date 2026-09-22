"""Returns rate from actset returned from solver."""
def get_rate_from_actset(action: str, actset: list[tuple[str, float | int]]) -> float | None {
    for act in actset {
        if act[0] == action {
            return float(act[1]);
        }
    }
}