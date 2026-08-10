""" Mask labels with Booleans that appear in row """
def _label_check(label_string: str, search_label: str) -> bool {
    return search_label in label_string.split(' ');
}