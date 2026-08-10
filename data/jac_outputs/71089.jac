"""The length of the string after evaluating."""
def parsed_length(line: str) -> int {
    len(eval(line))
}