"""
    bio2ot function for absa task
    """
def bio2ot_absa(absa_tag_sequence: list[str]) -> list[str] {
    new_absa_sequence = [];
    for absa_tag in absa_tag_sequence {
        if absa_tag == 'O' or absa_tag == 'EQ' {
            new_absa_sequence.append('O');
        } else {
            (pos, sentiment) = absa_tag.split('-');
            new_absa_sequence.append('T-%s' % sentiment);
        }
    }
    return new_absa_sequence;
}