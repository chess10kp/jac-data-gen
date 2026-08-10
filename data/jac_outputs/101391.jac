"""
This function splits a full name into a natural first name, last name
and middle initials.
"""
def full_name_natural_split(full_name: str) -> tuple[str, str, str] {
    parts = full_name.strip().split(' ');
    first_name = "";
    if parts {
        first_name = parts.pop(0);
    }
    if first_name.lower() == "el" and parts {
        first_name += " " + parts.pop(0);
    }
    last_name = "";
    if parts {
        last_name = parts.pop();
    }
    if last_name.lower() in ('i', 'ii') or last_name.lower() == 'iii' and parts {
        last_name = parts.pop() + " " + last_name;
    }
    middle_initials = "";
    for middle_name in parts {
        if middle_name {
            middle_initials += middle_name[0];
        }
    }
    return (first_name, middle_initials, last_name);
}