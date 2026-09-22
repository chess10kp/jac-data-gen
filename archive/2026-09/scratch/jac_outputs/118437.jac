"""
Create a return array and enumerate
through the array and append it to
the return array if the element is
not a space( )
"""
def remove_spaces(data: list[str]) -> list[str] {
    return [el for el in data if el is not " "];
}