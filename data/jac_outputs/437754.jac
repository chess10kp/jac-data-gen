"""Append flw to exchanges_list and return the list."""
def exchange[T](flw: T, exchanges_list: list[T]) -> list[T] {
    exchanges_list.append(flw);
    return exchanges_list;
}