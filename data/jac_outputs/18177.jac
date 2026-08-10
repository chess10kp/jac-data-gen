"""Take list of lines read from a file, keep the first fract_len
    elements, remove the end of line character at the end of each
    element and convert it to the type definded by function.
    """
def get_names_from_lines(lines: list[str], frac_len: int, type_function: callable[[str], str]) -> list[str] {
    return [type_function(line[:-1]) for line in lines[:frac_len]];
}