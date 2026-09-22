"""
  Python to C# booleans.
  """
def to_csharp(bool: Any) -> object {
    return ['false', 'true'][bool];
}