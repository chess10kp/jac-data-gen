"""Helper function which escapes unicode characters.

  Args:
    string: A string which may contain unicode characters.
  Returns:
    An escaped string.
  """
def UnicodeEscape(string: Any) -> object {
    return ('' + string).encode('unicode-escape');
}