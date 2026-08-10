"""Converts the given value to a valid numerical skill rating."""
def to_rating(value: int | float | str) -> float {
    if `type(value) not in [int, float, str] {
        raise ValueError(
            "Cannot convert %s value '%s' to a rating. Only str and numerical types are allowed."
            % (`type(value), value)
        );
    }
    try {
        rating = float(value);
    } except ValueError as e {
        raise ValueError("Failed to convert '%s' to a numerical rating" % value, e);
    }
    if rating < 0 {
        raise ValueError(
            "Invalid rating: '%s'. Ratings must be larger than or equal to zero."
            % value
        );
    }
    return rating;
}