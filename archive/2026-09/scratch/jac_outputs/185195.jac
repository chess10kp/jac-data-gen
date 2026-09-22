"""A target chooser that simply picks the first from the given list

    This is the default, particularly for the case of only one element in
    the list
    """
def first(targets: Any, cat: Any, kwargs: Any) -> object {
    targ = targets[0];
    if cat {
        s = cat[targ];
        if (kwargs and (targ in kwargs)) {
            s = kwargs.configure_new(**kwargs[targ]);
        }
        return s;
    } else {
        return targ;
    }
}