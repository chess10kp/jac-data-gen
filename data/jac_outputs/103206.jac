"""Ensure a sequence is always represented by a list of symbols."""
def as_list(arg: str | list[str]) -> list[str] {
    if isinstance(arg, str) {
        listed_arg = [arg];
    } else {
        listed_arg = arg[:];
    }
    return listed_arg;
}