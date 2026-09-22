"""Describe some aspect of the Item."""
def describe_something(game: bool, *args: str) -> bool {
    description = args[0];
    print(description);
    return False;
}