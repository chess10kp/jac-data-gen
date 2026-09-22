"""Return the sum of two polynomials (coefficient lists)."""
def add_two_polynomials(polynomial_1: list[int], polynomial_2: list[int]) -> list[int] {
    minimum_length = min(len(polynomial_1), len(polynomial_2));
    return_polynomial = [polynomial_1[k] + polynomial_2[k] for k in range(minimum_length)];
    if len(polynomial_1) > len(polynomial_2) {
        for k in range(len(polynomial_2), len(polynomial_1)) {
            return_polynomial.append(polynomial_1[k]);
        }
    } elif len(polynomial_1) < len(polynomial_2) {
        for k in range(len(polynomial_1), len(polynomial_2)) {
            return_polynomial.append(polynomial_2[k]);
        }
    }
    return return_polynomial;
}