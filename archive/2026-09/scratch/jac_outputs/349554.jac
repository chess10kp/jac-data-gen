"""Handle the case when other titles have been mentioned"""
def get_other_title(
    title_to_entities_all: dict[int | str, list[str] | None],
    other_title: dict[str, bool | int | str],
    token_location: int | str
) -> bool {
    other_title_found = False;
    if title_to_entities_all.get(token_location) is not None {
        other_title_found = True;
        other_title["found"] = True;
        other_title["location"] = token_location;
    }
    return other_title_found;
}