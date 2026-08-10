"""As i ran into https://www.python.org/dev/peps/pep-0616/ ."""
def removesuffix(string_: str, suffix: str) -> str {
    if suffix and string_.endswith(suffix) {
        return string_[:-len(suffix)];
    }
    return string_;
}