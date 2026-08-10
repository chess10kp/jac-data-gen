"""Returns the subdictionary specified by main_key
and sub_key, returning an empty dictionary if any is missing.
This is for use in the post-processing functions."""
def get_E2K_subdict(the_dict: dict[str, dict[str, object]], main_key: str, sub_key: str) -> dict[str, object] {
    return (the_dict[main_key].get(sub_key, {}) as dict[str, object]) if the_dict.get(main_key) else {};
}