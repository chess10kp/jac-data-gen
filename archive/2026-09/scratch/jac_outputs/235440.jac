"""Fancy indexing with tuples."""
def index(tup: tuple | list, ind: list[int]) -> tuple {
    tuple(tup[i] for i in ind)
}