"""Computes the total number of tuning entries."""
def length[T](database: dict[str, list[dict[str, list[T]]]]) -> int {
    sum(len(section["results"]) for section in database["sections"])
}