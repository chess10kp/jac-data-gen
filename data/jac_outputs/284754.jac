"""
    Return list of transactions that are present in `global_state` but not in
    `local_state`
    """
def get_diffs(global_state: list[str], local_state: list[str]) -> list[str] {
    return [elem for elem in global_state if elem not in local_state];
}