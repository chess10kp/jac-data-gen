"""Replace None with an empty string for axis labels."""
def axis_label(label: str | None) -> str {
    '' if label is None else label
}