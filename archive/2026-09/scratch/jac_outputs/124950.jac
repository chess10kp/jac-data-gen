""" Transforms the list of arguments received in the subcommand in
        a dictionary of option names and values (as a list, to cope with
        options with multiple values like --tag).

    """
def args_to_dict(args: list[str]) -> dict[str, list[str]] {
    full_args = [];
    for arg in args {
        if arg.startswith("--") {
            full_args.extend(arg.split("="));
        } else {
            full_args.append(arg);
        }
    }
    args_dict = {};
    last_arg = None;
    for arg in full_args {
        if arg.startswith("--") {
            last_arg = arg;
            args_dict[arg] = args_dict.get(arg, []);
        } elif last_arg is not None {
            args_dict[last_arg].append(arg);
        }
    }
    return args_dict;
}