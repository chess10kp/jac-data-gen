"""
    - the analytical expression for the model that aims at describing the experimental data
    - the X argument is an array of tuples of the form X=[,...,(xi_1,xi_2),...]
    """
def model_function(X: tuple[float, float, float], a: float, b: float, c: float) -> float {
    (nw1, nw2, I) = X;
    return a * pow(I, 2) * (nw1 + 0.5) + b * I * (nw2 + 0.5) + c;
}