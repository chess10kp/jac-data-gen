import from ast { literal_eval }

"""Parses a string line to a tuple."""
def parse_line(line: str) -> tuple[int | str | float | bool, ...] {
    try {
        entry = literal_eval(line);
        if not isinstance(entry, tuple) {
            raise Exception("Input parsed, but is not a tuple");
        }
    } except Exception {
        raise Exception("Could not evaluate (parse) input into an object");
    }
    return entry;
}