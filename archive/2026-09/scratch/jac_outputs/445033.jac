"""Returns True if the string represents a yes, False, if it represents
    no, and another string if it represents something else"""
def isYes(string: Any) -> object {
    value = string.strip().lower();
    if (value in ['yes', 'always', 'on', 'true']) {
        return True;
    }
    if (value in ['no', 'never', 'off', 'false', 'null']) {
        return False;
    }
    if (value in ['changed', 'change', 'onchange', 'on_change', 'diff']) {
        return 'change';
    }
}