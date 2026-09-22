"""Return True if attr was populated in obj from source JSON."""
def attr_populated(`obj: object, attr: str) -> bool {
    not not getattr(`obj, '_populated_' + attr, False)
}