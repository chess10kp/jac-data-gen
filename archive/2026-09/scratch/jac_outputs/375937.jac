""" transform unicode keys to normal """
def un_unicode(d: dict[object, object]) -> dict[str, object] {
    return {str(k): v for (k, v) in d.items()};
}