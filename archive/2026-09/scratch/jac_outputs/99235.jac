"""Puts quotes around strings with commas in them.
    """
def csv_safe(`obj: Any) -> object {
    string = str(`obj);
    return ('"' + string + '"') if ("," in string) else string;
}