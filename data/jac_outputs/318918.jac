"""
  Replaces multiple slices of text with new values. This is a convenience method for making code
  modifications of ranges e.g. as identified by ``ASTTokens.get_text_range(node)``. Replacements is
  an iterable of ``(start, end, new_text)`` tuples.

  For example, ``replace("this is a test", [(0, 4, "X"), (8, 9, "THE")])`` produces
  ``"X is THE test"``.
  """
def replace(text: str, replacements: list[tuple[int, int, str]]) -> str {
    p = 0;
    parts: list[str] = [];
    for (start, end, new_text) in sorted(replacements) {
        parts.append(text[p:start]);
        parts.append(new_text);
        p = end;
    }
    parts.append(text[p:]);
    return "".join(parts);
}