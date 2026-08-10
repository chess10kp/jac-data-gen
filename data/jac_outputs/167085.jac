"""
    Store the error_star state, which is the error between the target and market price.
    """
def store_error_star(
    params: dict[str, float],
    substep: int,
    state_history: list[dict[str, float]],
    state: dict[str, float],
    policy_input: dict[str, float]
) -> tuple[str, float] {
    error = policy_input["error_star"];
    return ("error_star", error);
}