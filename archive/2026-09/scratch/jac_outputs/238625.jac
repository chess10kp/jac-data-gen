"""lemma and pos are determined for a wordnet sense key."""
def get_lemma_pos_of_sensekey(sense_key: str) -> tuple[str, str] {
    if '%' not in sense_key {
        return ('', '');
    }
    (lemma, information) = sense_key.split('%');
    int_pos = information[0];
    match int_pos {
        case '1':
            this_pos = 'n';
        case '2':
            this_pos = 'v';
        case '3':
            this_pos = 'a';
        case '5':
            this_pos = 'a';
        case '4':
            this_pos = 'r';
        case _:
            this_pos = '';
    }
    return (lemma, this_pos);
}