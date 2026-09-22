"""Just the map function with the list function applied afterwards. Ah, GwR..."""
def mapz(function: callable, list_of_args: list[int]) -> list[int] {
    return list(map(function, list_of_args));
}