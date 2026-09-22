"""
This function should return a set of all ingredients from all listed dishes.
"""
def compile_ingredients(dishes: list[set[str]]) -> set[str] {
    compiled = set();
    for dish in dishes {
        compiled = compiled | dish;
    }
    return compiled;
}