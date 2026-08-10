"""Mask labels with Booleans that appear in row."""
def _drop_label_from_string(label_string: str, search_label: str) -> str {
    return ' '.join([label for label in label_string.split(' ') if search_label != label]);
}