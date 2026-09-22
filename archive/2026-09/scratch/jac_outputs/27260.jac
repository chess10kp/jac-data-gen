"""
  Returns *val* split on the ``'|'`` character.

  >>> _pipe_separated("a|b|c")
  ['a', 'b', 'c]
  """
def _pipe_separated(val: Any) -> object {
    return [
        s.strip()
        for s in val.split('|')
        if s.strip()
    ];
}