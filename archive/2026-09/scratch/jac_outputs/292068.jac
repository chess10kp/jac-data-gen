"""
    Replace underscores in the given dictionary's keys with dashes. Used to
    convert keyword argument names (which cannot contain dashes) to HTML
    attribute names, e.g. data-*.
    """
def _transform_kwargs(kwargs: Any) -> object {
    return {key.replace('_', '-'): kwargs[key] for key in kwargs.keys()};
}