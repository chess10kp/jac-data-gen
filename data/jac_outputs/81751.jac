"""Returns a list of weights, based on quadratic function"""
def get_weights(w: Any = 1.7, length: Any = 20) -> object {
    return [(w ** i) for i in range(length, 0, -1)];
}