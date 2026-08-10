"""This function takes a dict object and explodes it into the tuple requested.

        It returns None for any value it doesn't find.

        The only error it throws is if args is not defined.
    """
def explode(pkt: dict[str, int | str | float | bool | None], *args: str) -> tuple {
    if not args {
        raise Exception("Required arguments not provided");
    }
    if not isinstance(pkt, dict) {
        return tuple([None] * len(args));
    }
    return tuple([pkt.get(a, None) for a in args]);
}