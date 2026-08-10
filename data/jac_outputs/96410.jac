"""Given an optimizer state and some new ids for the parameters,
creates a new state with the new ids linked to the same tensors.

Useful when using an optimizer state used on some old model on a
new one.
"""
def repair_ids(
    shared_state: dict[int, object], original_id_to_label: dict[int, str], label_to_id: dict[str, int]
) -> dict[int, object] {
    return {label_to_id[original_id_to_label[param_id]]: state for (param_id, state) in shared_state.items()};
}