"""Test that duplicated arguments still cause no problem even if
    there are four of them."""
def test_quadruple_args_in_call(x: Any) -> object {
    def g(a: Any, b: Any, c: Any, d: Any) -> object {
        return (a * b * c * d);
    }
    return g(x, x, x, x);
}