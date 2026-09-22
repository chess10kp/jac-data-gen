"""sanitize validation in the form xn-yn z"""
def sanitize_validation(validators: str) -> tuple[int, int, str] {
    (joined_bounds, letter) = validators.split();
    (lower_bound, upper_bound) = map(int, joined_bounds.split("-"));
    return (lower_bound, upper_bound, letter);
}