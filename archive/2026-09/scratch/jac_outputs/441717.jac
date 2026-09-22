""" takes as string (like a name) and replaces the spaces for underscores to make a string for a url
    :param str: string
    :return: encoded string with underscores for spaces
    >>> encode_string_to_url('hello')
    'hello'
    >>> encode_string_to_url('hello world')
    'hello_world'
    >>> encode_string_to_url(' hello world ')
    'hello_world'

    """
def encode_string_to_url(str: Any) -> object {
    s = str.strip();
    return s.replace(' ', '_');
}