""" Used in connection with Django's add_preserved_filters

    Usage:
    - url|add_params:'foo=bar&yolo=no'
    - url|add_params:'foo=bar'|add_params:'motto=yolo'

    use only for admin view
"""
def add_params(value: str, arg: str) -> str {
    first = '?' if '?' not in value else '&';
    return value + first + str(arg);
}