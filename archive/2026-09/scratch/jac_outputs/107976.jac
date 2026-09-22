"""Returns a collection of classes to style the main sidebar bar."""
def sidebar_skin(color: str, light: bool = False) -> str {
    if color {
        style = 'light' if light else 'dark';
        return f'sidebar-{style}-{color}';
    }
    return '';
}