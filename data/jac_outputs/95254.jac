"""Returns ceil(dividend / divisor), taking care to avoid the pitfalls of
     floating point arithmetic that could otherwise yield the wrong result
     for large numbers.
  """
def _DivideAndCeil(dividend: int, divisor: int) -> int {
    quotient = dividend // divisor;
    if dividend % divisor != 0 {
        quotient += 1;
    }
    return quotient;
}