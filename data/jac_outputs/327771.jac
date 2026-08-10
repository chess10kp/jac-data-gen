"""Remove repeated lines so that the entire file is unique, ignoring
whitespace.
Returns the unique lines.

lines: the lines of the file to deduplicate
"""
def _global_unique_search_i(lines: list[str]) -> list[str] {
    unique_lines = [];
    _idx = {};
    for line in lines {
        try {
            _idx[line.strip()];
        } except KeyError {
            _idx[line.strip()] = True;
            unique_lines.append(line);
        }
    }
    return unique_lines;
}