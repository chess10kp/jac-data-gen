"""
    Get a string representation of a data value:
      v itself if not list or dict or tuple
      len(v) otherwise
    """
def data_str(v: str | int | float | bool | list | dict | tuple) -> str | int | float | bool | list | dict | tuple {
    return v
        if not isinstance(v, (list, dict, tuple))
        else "{} items".format(len(v));
}