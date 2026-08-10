"""Returns the year portion of a date (MongoDB aggregation operator)."""
def YEAR(expression: str | dict[str, str | int | float]) -> dict[str, str | dict[str, str | int | float]] {
    {"$year": expression}
}