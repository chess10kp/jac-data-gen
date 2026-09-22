"""Turn a single line from the cow data file into a list of [cow, weight]."""
def cow_line_splitter(cow_line: str) -> list[str] {
    cow_line.strip().split(",")
}