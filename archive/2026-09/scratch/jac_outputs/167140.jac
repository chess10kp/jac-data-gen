"""Split volume from journal title.

    We need this because sometimes the volume is attached to the journal title
    instead of the volume. In those cases we move it here from the title to the
    volume.
    """
def split_volume_from_journal(citation_elements: list[dict[str, str]]) -> list[dict[str, str]] {
    for el in citation_elements {
        if el['type'] == 'JOURNAL' and ';' in el['title'] {
            (el['title'], series) = el['title'].rsplit(';', 1);
            el['volume'] = series + el['volume'];
        }
    }
    return citation_elements;
}