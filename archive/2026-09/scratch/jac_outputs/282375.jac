"""Determine if cast member is relevant to our search."""
def isQualifiedActor(stringList: list[str]) -> bool {
    not_known_for_anything = stringList[-1] == '\\N';
    not_an_actor = 'actor' not in stringList[-2];
    is_dead = stringList[-3].isdigit();
    has_no_birth_year = stringList[-4] == '\\N';
    first_or_last_name_is_a_number = stringList[1].isdigit() or stringList[-5].isdigit();
    return not (
        not_known_for_anything
        or not_an_actor
        or is_dead
        or has_no_birth_year
        or first_or_last_name_is_a_number
    );
}