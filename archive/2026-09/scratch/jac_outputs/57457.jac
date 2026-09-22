"""
    The flatten2Class method answers the class string, made from space separated class names. If
    cssClass is a tuple or list, then merge the content. Check recursively in
    case the names are nested. If the classes is empty or None or contain an empty
    element, then this is ignored.
    """
def flatten2Class(*args: str | list | tuple | None) -> str {
    result = [];
    for cssClass in args {
        if isinstance(cssClass, str) {
            result.append(cssClass);
        } elif isinstance(cssClass, (tuple, list)) {
            s = [];
            for part in cssClass {
                flattened = flatten2Class(part);
                s.append(flattened);
            }
            result.append(' '.join(s));
        } elif cssClass is None {
            continue;
        } else {
            raise TypeError(
                (
                    '[Transformer.flatten2Class] Class part must be None, string, tuple or list, not "%s"'
                    % cssClass
                )
            );
        }
    }
    return ' '.join(result);
}