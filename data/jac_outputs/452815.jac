"""Normalize Paizo HTML attribute names to a canonical form."""
def normalize_attribute(attr: str) -> str {
    attr = attr.strip();
    if attr.endswith(':') {
        attr = attr[:-1];
    }
    if attr == 'Prerequisites' {
        attr = 'Prerequisite';
    }
    if attr == 'Note' {
        attr = 'Prerequisite';
    }
    if attr == 'Benefits' {
        attr = 'Benefit';
    }
    if attr == 'Leadership Modifiers' {
        attr = 'Benefit';
    }
    assert attr in ('Prerequisite', 'Benefit', 'Normal', 'Special');
    return attr.lower();
}