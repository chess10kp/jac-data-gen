"""Split library name from version specifier when present."""
def get_library_name(library_name: str) -> str {
    name = library_name;
    for sign in ['!=', '==', '>=', '~='] {
        name = name.split(sign)[0];
    }
    return name.strip();
}