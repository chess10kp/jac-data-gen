""" A '-' at the beginning of a line is a special charter in YAML,
    used backslash to escape, need to remove the added backslash for local run.
    """
def rm_backslash(params: dict[str, str]) -> dict[str, str] {
    return {k.strip('\\'): v for (k, v) in params.items()};
}