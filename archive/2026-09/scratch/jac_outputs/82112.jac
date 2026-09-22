"""Returns true if `entity` is a Cybox object"""
def is_cybox(entity: object) -> bool {
    try {
        return entity.__module__.startswith("cybox.");
    } except AttributeError {
        return False;
    }
}