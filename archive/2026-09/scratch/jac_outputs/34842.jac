"""Collect the skill names to turn on (actually this should be the only skill because active skill is the only)
        which were linked to from one dff-skill to another one.

    Returns:
        list of skill names to turn on
    """
def get_linked_to_dff_skills(
    dff_shared_state: Any, current_turn: Any, prev_active_skill: Any
) -> object {
    to_skills = [];
    for to_skill in dff_shared_state.get("cross_links", {}).keys() {
        cross_links = dff_shared_state.get("cross_links", {})[to_skill];
        if (
            (
                cross_links.get(str((current_turn - 1)), {}).get("from_service", "")
                == prev_active_skill
            )
            or (
                cross_links.get(str((current_turn - 2)), {}).get("from_service", "")
                == prev_active_skill
            )
        ) {
            to_skills.append(to_skill);
        }
    }
    return to_skills;
}