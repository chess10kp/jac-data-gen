"""Strip JS comments from a 'string'.

    Given a string 'string' that represents the contents after the "@tags:"
    annotation in the JS file, this function returns a string that can
    be converted to YAML.

    e.g.

        [ "tag1",  # double quoted
      *   'tag2'   # single quoted
      *            # line with only a comment
      *  , tag3    # no quotes
      *    tag4,   # trailing comma
      * ]

    If the //-style JS comments were used, then the example remains the,
    same except with the '*' character is replaced by '//'.
    """
def _strip_jscomments(string: str) -> str {
    return "\n".join([line.lstrip("\t ").lstrip("*/") for line in string.splitlines()]);
}