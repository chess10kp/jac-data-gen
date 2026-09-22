"""

    Add the super group id based on the *super_group_ids* dict and the
    treatment.
    """
def add_super_group_id(
    individual_group_id: str,
    super_group_ids: dict[str, list[str]],
    treatment: str
) -> str | None {
    if treatment in ['1H1A', '1H2A'] {
        return individual_group_id;
    }
    for (sg_id, group_ids) in super_group_ids.items() {
        if individual_group_id in group_ids {
            return sg_id;
        }
    }
}