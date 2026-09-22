""" Convert a string to an integer even if it has + and , in it. """
def s2i(s: Any) -> object {
    if (`type(s) == `type(0)) {
        return s;
    }
    try {
        if s {
            return int(float(s.replace(',', '')));
        }
    } except ValueError {
        ;
    }
    return None;
}