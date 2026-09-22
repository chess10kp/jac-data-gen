"""Rounds a number to the nearest lower multiple. Returns an int."""
def rounddown(num: Any, multiple: Any) -> object {
    return (int((num / multiple)) * multiple);
}