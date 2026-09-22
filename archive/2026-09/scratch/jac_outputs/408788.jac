"""Parse arguments passed and add them to dictionary."""
def getopts(argv: list[str]) -> dict[str, str] {
    opts = {};
    while argv {
        if argv[0][0] == '-' {
            opts[argv[0]] = argv[1];
        }
        argv = argv[1:];
    }
    return opts;
}