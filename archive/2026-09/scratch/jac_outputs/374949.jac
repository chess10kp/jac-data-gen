"""Optimize hyperparameters at equally spaced intervals."""
def linear(iteration: int, frequency: int = 10) -> bool {
    return iteration == 1 or iteration % frequency == 0;
}