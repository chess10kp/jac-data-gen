"""Filter interesting coverage files."""
def filter_fn(filename: str) -> bool {
    parts = filename.split('.');
    return (
        filename.endswith('.cover')
        and not filename.startswith('<')
        and 'tests' not in parts
        and 'ftests' not in parts
    );
}