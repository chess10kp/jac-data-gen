"""Helper function for chaining function calls in a Python lambda expression.

    Part of a poor-man's functional programming suite used to define several pfainspector commands as one-liners."""
def do(*args: object) -> object {
    args[-1]
}