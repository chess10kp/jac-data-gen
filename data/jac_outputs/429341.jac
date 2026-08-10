"""
    Method decorator to indicate that a method definition shall
    silently be ignored if it already exists in the target class.
    """
def no_replace(f: Callable) -> Callable {
    setattr(f, '__no_replace', True);
    return f;
}