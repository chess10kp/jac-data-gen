""" referenced_section - a list containing referenced chapter
    and paragraph.
    """
def is_valid_section_format(referenced_section: Any) -> object {
    return ((referenced_section is not None) and (len(referenced_section) == 2));
}