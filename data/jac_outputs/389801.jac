"""
Ensure that elements is a type of sequence, otherwise
it converts it to a list with only one element.
"""
def make_sequence(elements: list | set | tuple | None | int | float | str | bool) -> list | set | tuple {
    if isinstance(elements, (list, set, tuple)) {
        return elements;
    } elif elements is None {
        return [];
    } else {
        return [elements];
    }
}