"""
Exclude or include brackets based on filter lists.
"""
def exclude_bracket(
    enabled: bool, filter_type: str, language_list: list[str], language: str | None
) -> bool {
    exclude = True;
    if enabled {
        if filter_type == 'blacklist' {
            exclude = False;
            if language != None and any(language == item.lower() for item in language_list) {
                exclude = True;
            }
        } elif filter_type == 'whitelist' {
            if language != None and any(language == item.lower() for item in language_list) {
                exclude = False;
            }
        }
    }
    return exclude;
}