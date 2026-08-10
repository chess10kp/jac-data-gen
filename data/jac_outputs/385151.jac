"""Helper function to check if a string is shorter than expected length of not.

    :param int length: Maximum length of an expected string.
    :param str content: A string to be validated.

    :return str: A string of error message if validation fails, or an empty string if validation succeeds.
    """
def _length_checker(length: Any, content: Any) -> object {
    if (len(content) > length) {
        return 'Invalid label: {0} has {1} characters. The maximum is {2}.\n'.format(
            content, len(content), length
        );
    } else {
        return '';
    }
}