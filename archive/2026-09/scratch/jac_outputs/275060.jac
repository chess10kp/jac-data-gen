"""
    Extract scalar reward from trial result.

    Raises
    ------
    RuntimeError
        Incorrect final result: the final result should be float/int,
        or a dict which has a key named "default" whose value is float/int.
    """
def extract_scalar_reward(value: int | float | dict[str, int | float], scalar_key: str = 'default') -> int | float {
    if isinstance(value, float) or isinstance(value, int) {
        reward = value;
    } elif (
        isinstance(value, dict)
        and scalar_key in value
        and isinstance(value[scalar_key], (float, int))
    ) {
        reward = value[scalar_key];
    } else {
        raise RuntimeError(
            'Incorrect final result: the final result should be float/int, or a dict which has a key named "default" whose value is float/int.'
        );
    }
    return reward;
}