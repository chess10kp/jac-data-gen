"""dir."""
def dir(object: object = None) -> object {
    return object.__dir__();
}