"""Stupidly makes value plural (adds s) if condition is True"""
def make_plural(condition: Any, value: Any) -> object {
    return (str(value) + "s") if condition else str(value);
}