"""Returns a list of indices in case of re-running with-items."""
def _get_with_item_indices(exs: list[object]) -> list[int] {
    return sorted(set(getattr(ex, 'runtime_context')['with_items_index'] for ex in exs));
}