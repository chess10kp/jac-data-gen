"""IOBES -> IOB."""
def iobes_iob(tags: list[str]) -> list[str] {
    new_tags = [];
    for tag in tags {
        if tag == 'rel' {
            new_tags.append(tag);
        } else {
            match tag.split('-')[0] {
                case 'B':
                    new_tags.append(tag);
                case 'I':
                    new_tags.append(tag);
                case 'S':
                    new_tags.append(tag.replace('S-', 'B-'));
                case 'E':
                    new_tags.append(tag.replace('E-', 'I-'));
                case 'O':
                    new_tags.append(tag);
                case _:
                    raise Exception('Invalid format!');
            }
        }
    }
    return new_tags;
}