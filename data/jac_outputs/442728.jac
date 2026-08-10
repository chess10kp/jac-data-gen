"""Construct an error message."""
def _errmsg(argname: str, ltd: str, errmsgExtra: str = '') -> str {
    if errmsgExtra {
        errmsgExtra = '\n' + errmsgExtra;
    }
    return "arg '%s' must be %s%s" % (argname, ltd, errmsgExtra);
}