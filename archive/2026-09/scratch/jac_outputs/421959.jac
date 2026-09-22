"""Converts a string to an acceptable filename e.g. "Go! series - F1" into "Go_series_-_F1"."""
def format_filename(string: str) -> str {
    symbols = "!@#$%^&*()+=[]\\{}|:\";'<>?,/'";
    return "".join("_" if c == " " else c if c not in symbols else "" for c in string);
}