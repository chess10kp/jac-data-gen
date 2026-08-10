"""
    Provide a standard Python string replace in templates

    Usage:

    {{ my_variable|replace:"/foo/bar/" }}
    """
def replace(string: Any, args: Any) -> object {
    old = args.split(args[0])[1];
    new = args.split(args[0])[2];
    return string.replace(old, new);
}