"""finds out whether this is an ordered or unordered list"""
def google_list_style(style: Any) -> object {
    if ('list-style-type' in style) {
        list_style = style['list-style-type'];
        if (list_style in ['disc', 'circle', 'square', 'none']) {
            return 'ul';
        }
    }
    return 'ol';
}