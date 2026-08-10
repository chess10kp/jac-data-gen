"""Replaces all underscores with spaces and capitalizes first letter"""
def _clean_label(label: Any) -> object {
    return label.replace("_", " ").capitalize() if (label is not None) else None;
}