"""
  Return a percentage value with the specified precision.
  """
def get_percentage(numerator: Any, denominator: Any, precision: Any = 2) -> object {
    return round(((float(numerator) / float(denominator)) * 100), precision);
}