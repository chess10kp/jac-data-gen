"""Get all unique (user, lexeme) pairs."""
def get_unique_user_lexeme(data_dict: dict[str, dict[str, str]]) -> list[tuple[str, str]] {
    pairs = {(u_id, lexeme) for u_id in data_dict for lexeme in data_dict[u_id]};
    return sorted(pairs);
}