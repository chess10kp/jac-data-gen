"""checks if an object is exactly an instance of a given class"""
def is_same_class(`obj: Any, a_class: Any) -> object {
    return (`type(`obj) is a_class);
}