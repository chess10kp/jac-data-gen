"""Allows empty initialization of Module, useful when data must be added."""
def seqs_from_empty(`obj: object, *args: object, **kwargs: object) -> tuple[list[object], list[object]] {
    return ([], []);
}