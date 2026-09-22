""" Convert a parameter name from snake_case to PascalCase as used for AWS IAM api parameters.

    :param word: Dictionary of Resilient Function parameters.
    :return: Converted  string.
    """
def snake_to_pascal(param: str) -> str {
    return ''.join((x.capitalize() or '_') for x in param.split('_'));
}