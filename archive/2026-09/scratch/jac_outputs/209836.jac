"""Get cardholder note that begins with a CC- prefix from a PO line record."""
def get_cardholder_from_notes(po_line_record: dict[str, list[dict[str, str]]]) -> str {
    cardholder = "No cardholder note found";
    for note in [
        n
        for n in po_line_record.get("note", [{}])
        if n.get("note_text", "").startswith("CC-")
    ] {
        cardholder = note["note_text"][3:];
    }
    return cardholder;
}