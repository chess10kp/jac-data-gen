"""Creates a formatted HTML string, underlining detected entities."""
def prepare_entity_html(entity_groupings: list[tuple[str, str | bool]], binary: bool = True) -> str {
    string_groupings = [];
    for (entity, flag) in entity_groupings {
        if flag {
            if binary {
                string_groupings.append(
                    f'<u style="background-color:DodgerBlue;color:white;">{entity}</u>'
                );
            } else {
                string_groupings.append(
                    f'<u style="background-color:DodgerBlue;color:white;">{entity}</u> <span style="background-color:LightGray;">({flag})</span>'
                );
            }
        } else {
            string_groupings.append(entity);
        }
    }
    return ' '.join(string_groupings);
}