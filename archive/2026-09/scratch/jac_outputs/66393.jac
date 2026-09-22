"""Return datalines filtered to those containing the specified tech."""
def data_by_tech(datalines: list[str], tech: str) -> list[str] {
    return [line for line in datalines if tech in line];
}