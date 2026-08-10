"""Check predicates at runtime and return matched value or None."""
def _runtime_maybe(ctx: object, variants: list[tuple[object, bool | Callable[[object], bool]]]) -> object | None {
    for (value, predicate) in variants {
        if callable(predicate) {
            if predicate(ctx) {
                return value;
            }
        } elif predicate {
            return value;
        }
    }
}