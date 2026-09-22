"""
    For parts longer than three characters, we reveal the first two characters and obscure the rest.

    Parts up to three characters long are handled as special cases.

    We reveal no more than 50% of the characters for any part.

    :param part:
    :return:
    """
def _obscure_email_part(part: Any) -> object {
    if not part {
        return part;
    }
    length = len(part);
    if (length == 1) {
        return '*';
    }
    if (length == 2) {
        return (part[:1] + '*');
    }
    if (length == 3) {
        return (part[:1] + '**');
    }
    if (length > 3) {
        return (part[:2] + ('*' * (length - 2)));
    }
}