"""Change a temp section into its original. If it is its original it will return what was given."""
def temp_to_orig_section(temp_sec: str) -> str {
    section = temp_sec;
    if temp_sec.startswith(('1', '2', '3', '4', '5', '6', '7', '8', '9')) and '~|~' in temp_sec {
        section = temp_sec.split('~|~', 1)[1];
    }
    return section;
}