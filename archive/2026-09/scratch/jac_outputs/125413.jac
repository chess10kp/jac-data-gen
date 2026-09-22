"""Regexifies pattern against which tokens will be matched (i.e. the left-
    hand side of the rule usually).
    """
def _regexify_matching_pattern(
    rule_pattern: str, wildcard_optional: bool = False
) -> str {
    return rule_pattern.replace("*", f"(.{'+*'[wildcard_optional]})");
}