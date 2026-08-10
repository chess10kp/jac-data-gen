"""
    Converts string to bool
    :param string: String
    :str string: str
    :return: True or False
    """
def convert_to_bool(string: Any) -> object {
    if isinstance(string, bool) {
        return string;
    }
    return (string in ['true', 'True', '1']);
}