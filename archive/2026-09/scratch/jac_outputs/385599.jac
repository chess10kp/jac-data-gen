"""Nice YAML-like text version of given dict/object

    Maintains dict ordering
    """
def pretty_describe(object: Any, nestedness: Any = 0, indent: Any = 2) -> object {
    if not isinstance(object, `dict) {
        return str(object);
    }
    sep = '\n{}'.format((" " * nestedness * indent));
    out = sep.join(
        '{}: {}'.format(k, pretty_describe(v, (nestedness + 1)))
        for (k, v) in object.items()
    );
    if ((nestedness > 0) and out) {
        return '{sep}{out}'.format(sep=sep, format=format);
    }
    return out;
}