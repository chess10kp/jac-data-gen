"""Parse arguments passed to a graphql query name or nodes and returns a string of arguments

    Args:
        dict (list):
            The arguments you want passed to your node or query name. An example for retrieving balances is:

            {"cryptocurrency":"bitcoin"}

    Returns:
        A string of comma-separated arguments key-value pairs as in the graphql standard like (cryptocurrency: bitcoin, status:open)

    """
def parse_args(args: dict[str, str]) -> str {
    return ",".join(["{}:{}".format(pair[0], pair[1]) for pair in args.items()]);
}