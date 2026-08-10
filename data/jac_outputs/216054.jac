"""Get reputation of user."""
def _get_reputation(followers: int, following: int) -> float {
    try {
        return followers / (followers + following);
    } except ZeroDivisionError {
        return 0.0;
    }
}