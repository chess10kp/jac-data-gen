"""Disables the projection key if the flag name filter expr is false.

  Args:
    r: A JSON-serializable object.
    expr: A command flag filter name expression. See `gcloud topic filters` for
      details on filter expressions. The expression variables are flag names
      without the leading *--* prefix and dashes replaced by underscores.

  Example:
    The "table(name, value.if(NOT short_format))" format will list a value
    column if the *--short-format* command line flag is not specified.

  Returns:
    r
  """
def TransformIf(r: dict[str, str | int | float | bool | None], expr: str) -> dict[str, str | int | float | bool | None] {
    _ = expr;
    return r;
}