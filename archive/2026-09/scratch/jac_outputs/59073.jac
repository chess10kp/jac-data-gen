"""
    Remove all leading/trailing spaces for each line.
    """
def align_on_left(txt: str) -> str {
    txt_out = [curr_line.rstrip(" ").lstrip(" ") for curr_line in txt.split("\n")];
    return "\n".join(txt_out);
}