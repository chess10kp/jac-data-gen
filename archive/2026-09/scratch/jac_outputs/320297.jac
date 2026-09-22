"""
    The algorithm stops as soon as the current objective function value
    is less or equal then limit.
    """
def objective_limit(energy: Any, limit: Any) -> object {
    if (energy <= limit) {
        return True;
    } else {
        return False;
    }
}