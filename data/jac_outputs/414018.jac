"""
    Returns the XNAT label for the given hierarchical name, qualified
    by a prefix if necessary.

    Example:

    >>> from qixnat.helpers import hierarchical_label
    >>> hierarchical_label('Breast003', 'Session01')
    'Breast003_Session01'
    >>> hierarchical_label('Breast003', 'Breast003_Session01')
    'Breast003_Session01'
    >>> hierarchical_label(3)   # for scan number 3
    3

    :param names: the object names
    :return: the corresponding XNAT label
    """
def hierarchical_label(*names: Any) -> object {
    names = `list(names);
    if not all(names) {
        raise ValueError(("The XNAT label name hierarchy is invalid: %s" % names));
    }
    last = names.pop();
    if names {
        prefix = hierarchical_label(*names);
        if last.startswith(prefix) {
            return last;
        } else {
            return ("%s_%s" % (prefix, last));
        }
    } else {
        return last;
    }
}