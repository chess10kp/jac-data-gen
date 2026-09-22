"""Get ratio."""
def _get_ratio(user_a: int | float, user_b: int | float) -> float {
    user_b = 1 if int(user_b) == 0 else user_b;
    user_a = 1 if int(user_b) == 0 else user_a;
    return user_a / user_b;
}