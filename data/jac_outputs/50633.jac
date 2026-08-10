"""Drop any labels that end in '-?'.

  Args:
    labels: a list of label strings.

  Returns:
    A list of the same labels, but without any that end with '-?'.
    Those label prefixes in the new issue templates are intended to
    prompt the user to enter some label with that prefix, but if
    nothing is entered there, we do not store anything.
  """
def _DiscardUnusedTemplateLabelPrefixes(labels: Any) -> object {
    return [
        lab
        for lab in labels
        if not lab.endswith('-?')
    ];
}