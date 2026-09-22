"""Extract username of a follow button from a dialog box."""
def dialog_username_extractor(buttons: object) -> list[str] {
    if not isinstance(buttons, list) {
        buttons = [buttons];
    }
    person_list = [];
    for person in buttons {
        if person and hasattr(person, 'text') and person.text {
            try {
                person_list.append(
                    person.find_element_by_xpath(
                        "../../../*"
                    ).find_elements_by_tag_name(
                        "a"
                    )[1].text
                );
            } except IndexError {
                ;
            }
        }
    }
    return person_list;
}