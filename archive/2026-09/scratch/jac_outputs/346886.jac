"""Verb: No-op."""
def _type(`obj: Any) -> object {
    print(`type(`obj));
    return `obj;
}