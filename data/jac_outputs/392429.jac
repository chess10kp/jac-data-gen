"""Return the values corresponding to the choices."""
def choose_in(keys: list[object], values: list[object], choices: list[object]) -> list[object] {
    dictionary = dict(list(zip(keys, values)));
    return [dictionary[key] for key in choices];
}