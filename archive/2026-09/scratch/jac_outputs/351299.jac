"""takes a dictionary and applies the function to every element"""
def map_dict[K, V, W](fn: Callable[[V], W], d: dict[K, V]) -> dict[K, W] {
    return `type(d)(map(lambda (kv: tuple[K, V]) { (kv[0], fn(kv[1])); }, d.items()));
}