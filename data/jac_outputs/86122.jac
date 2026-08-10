"""
    Translate the identifier of a mapry composite to a variable name in C++.

    :param identifier: mapry identifier of a composite
    :return: translated to a C++ variable name

    >>> as_variable('Some_URL_class')
    'some_url_class'

    """
def as_variable(identifier: str) -> str {
    return identifier.lower();
}