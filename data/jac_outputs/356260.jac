""" function returns a copy of old_office updated with values from new if applicable """
def update_office(
    old_office: dict[str, str | int | float | bool | None],
    new_office: dict[str, str | int | float | bool | None]
) -> dict[str, str | int | float | bool | None] {
    updated_office = old_office.copy();
    for (newfield, newval) in new_office.items() {
        for (oldfield, oldval) in old_office.items() {
            if oldfield == newfield and newval != oldval {
                updated_office[oldfield] = newval;
                break;
            }
        } else {
            updated_office[newfield] = newval;
        }
    }
    return updated_office;
}