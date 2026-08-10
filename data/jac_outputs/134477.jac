"""Generates a change list for a single state change."""
def _get_change_list(state_name: str, property_name: str, new_value: str | int | float | bool | None) -> list[dict[str, str | int | float | bool | None]] {
    return [
        {
            'cmd': 'edit_state_property',
            'state_name': state_name,
            'property_name': property_name,
            'new_value': new_value
        }
    ];
}