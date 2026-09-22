"""
    The full repr representation of PVT model takes too much space to print all values inside a array.
    Making annoying to debug Subjects that has a PVT model on it, due to seventy-four lines with only numbers.
    """
import re;

def collapse_array_repr(value: int | float | str | bool | bytes | list | dict) -> str {
    text: str = repr(value);
    return re.sub(r"array\(\[.*?\]\)", "array([...])", text, flags=16);
}