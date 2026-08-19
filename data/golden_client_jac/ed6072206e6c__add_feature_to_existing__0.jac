node Note { has body: str, pinned: bool = False; }

def add_note(body: str) -> Note {
    note = root ++> Note(body=body);
    return note[0];
}
