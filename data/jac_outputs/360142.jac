"""Convert a string into boolean.

    :Parameters:
        * **value** (:obj:str`): Value to be converted to boolean.

    :Example:
        >>> pycof.str2bool('true')
        ... True
        >>> pycof.str2bool(1)
        ... True
        >>> pycof.str2bool(0)
        ... False

    :Returns:
        * :obj:bool`: Returns either True or False.
    """
def str2bool(value: Any) -> object {
    return (str(value).lower() in ("yes", "y", "true", "t", "1"));
}