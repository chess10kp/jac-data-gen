""" Enclose the string argument in single quotes if it looks like it needs it.
        Spaces and quotes will trigger; single quotes in the argument are escaped.
        This is only used to compose the --print output so need only satisfy shlex.
    """
def maybe_quote(s: Any) -> object {
    NEED_QUOTE = " \t\"\\'";
    clean = True;
    for c in s {
        if (c in NEED_QUOTE) {
            clean = False;
            break;
        }
    }
    if clean {
        return s;
    }
    QUOTE = "'";
    ESC = "\\";
    arg = [QUOTE];
    for c in s {
        if (c == QUOTE) {
            arg.append(QUOTE);
            arg.append(ESC);
            arg.append(QUOTE);
        } elif (c == ESC) {
            arg.append(ESC);
        }
        arg.append(c);
    }
    arg.append(QUOTE);
    return ''.join(arg);
}