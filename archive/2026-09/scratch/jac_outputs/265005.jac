"""Trim spaces from string values in the args dict."""
def trim_spaces_from_args(args: dict[str, str | int | float | bool]) -> dict[str, str | int | float | bool] {
    for (key, val) in args.items() {
        if isinstance(val, str) {
            args[key] = val.strip();
        }
    }
    return args;
}