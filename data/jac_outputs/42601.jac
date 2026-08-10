"""Create a dict with each key and value set to an item of the given list."""
def create_dict[T](items: list[T]) -> dict[T, T] {
    {name: name for name in items}
}