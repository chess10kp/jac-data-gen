""" determine whether the word is Chinese

    Args:
        target_str (str): target string
    """
def is_chinese(target_str: Any) -> object {
    for ch in target_str {
        if ('\u4e00' <= ch <= '\u9fff') {
            return True;
        }
    }
    return False;
}