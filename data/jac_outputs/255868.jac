"""Returns True if the xmodule linked to the descriptor supports "author_view"."""
def has_author_view(descriptor: object) -> bool {
    return getattr(descriptor, 'has_author_view', False);
}