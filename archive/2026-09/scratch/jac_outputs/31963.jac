"""Turn the given HTTP request arguments from bytes to str."""
def stringifyRequestArgs(args: dict[bytes | str, list[bytes | str]]) -> dict[str, list[str]] {
    str_args: dict[str, list[str]] = {};
    for (arg, values) in args.items() {
        if isinstance(arg, bytes) {
            arg = arg.decode("utf-8");
        }
        decoded_values: list[str] = [
            value.decode("utf-8") if isinstance(value, bytes) else value
            for value in values
        ];
        str_args[arg] = decoded_values;
    }
    return str_args;
}