"""Negate a single element"""
def neg(element: str) -> str {
    element[1:] if element.startswith("~") else "~" + element
}