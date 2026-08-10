"""Insert addition command line options into the given command and return the result."""
def insert_options(command: list[str], options: list[str] | None) -> list[str] {
    result = [];
    for arg in command {
        if options and arg.startswith("--") {
            result.extend(options);
            options = None;
        }
        result.append(arg);
    }
    return result;
}