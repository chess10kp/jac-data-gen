"""Strip characters that the APIC deems are illegal."""
def strip_illegal_characters(name: str) -> str {
    chars_all_good = True;
    for character in name {
        if character.isalnum() or character in ('_', '.', ':', '-') {
            continue;
        }
        chars_all_good = False;
        name = name.replace(character, '');
    }
    if chars_all_good {
        return name;
    }
    return strip_illegal_characters(name);
}