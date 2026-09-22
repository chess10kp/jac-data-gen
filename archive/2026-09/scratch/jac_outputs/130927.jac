"""
    Return a list from the given string.

    Example:
        print listToString('apple, pear, cherry')

        # ['apple', 'pear', 'cherry']

    :type data: str
    :rtype: list
    """
def stringToList(data: Any) -> object {
    data = '["' + str(data) + '"]';
    data = data.replace(' ', '');
    data = data.replace(',', '","');
    return eval(data);
}