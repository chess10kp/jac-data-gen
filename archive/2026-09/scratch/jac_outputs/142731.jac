"""
https://stackoverflow.com/questions/480214/how-do-you-remove-duplicates-from-a-list-whilst-preserving-order
"""
def remove_dups[T](seq: list[T]) -> list[T] {
    seen = set();
    seen_add = seen.add;
    return [x for x in seq if not (x in seen or seen_add(x))];
}