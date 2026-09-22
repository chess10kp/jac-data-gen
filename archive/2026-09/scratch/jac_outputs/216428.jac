"""Pretty print a command line.

    Take a command line suitable to be passed to a Popen-like call and
    returns a string that represents it in a way that preserves the
    structure of arguments and can be passed to bash as is.

    More precisely, delimitate every item of the command line with
    single apstrophes and join all the arguments separating them with
    spaces.

    """
def pretty_print_cmdline(cmdline: Any) -> object {
    return " ".join([("'%s'" % x.replace("'", "'\"'\"'")) for x in cmdline]);
}