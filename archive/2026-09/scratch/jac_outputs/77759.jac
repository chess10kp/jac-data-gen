"""Access the global lineeditor instance."""
def global_line_editor(gle: object | None = None) -> object {
    if gle is not None {
        _gle_data = gle;
    }
    return _gle_data;
}