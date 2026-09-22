"""Generate all possible permutations of a list of options."""
def all_permutations(options: list[list[object]]) -> list[list[object]] {
    solutions = [[]];
    for option_set in options {
        solutions = [item + [option] for item in solutions for option in option_set];
    }
    return solutions;
}