"""Report whether any arguments in the args list appear in the list l."""
def any_alt_args_in_list(args: dict[str, dict[str, object]], l: list[str]) -> bool {
    any(a in l for a in args.get('alt_args', {}))
}