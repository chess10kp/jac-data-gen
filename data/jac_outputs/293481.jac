"""compute shear modulus from poisson ratio mu and Youngs modulus E
    """
def mu2G(mu: Any, E: Any) -> object {
    return (E / (2 * (1 + mu)));
}