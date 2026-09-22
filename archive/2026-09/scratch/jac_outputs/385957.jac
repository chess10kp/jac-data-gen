"""Create pipe separated string."""
def join(*args: Any) -> object {
    return "|".join(str(a) for a in args);
}