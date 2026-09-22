"""Extract both parts from a string of the form part1.part2.
The '.' used is the last in the string.
Returns a pair (part1, part2).
Useful for parsing machine.buildType filenames."""
def _extractDotSeparatedPair(string: str) -> tuple[str, str] {
    i = string.rfind('.');
    return (string[:i], string[(i + 1):]);
}