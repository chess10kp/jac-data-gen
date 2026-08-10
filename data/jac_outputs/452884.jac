"""
    Using an ast.FunctionDef node, create a items list node that
    will give us the passed in args by name.

    def whee(bob, frank=1):
        pass

    whee(1, 3) => [('bob', 1), ('frank', 3)]
    whee(1) => [('bob', 1), ('frank', 1)]
    """
def func_args_realizer(args: list[str]) -> str {
    items = map("('{0}', {0})".format, args);
    return "[ {0} ]".format(', '.join(items));
}