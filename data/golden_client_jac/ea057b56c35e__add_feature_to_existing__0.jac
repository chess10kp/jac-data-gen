def duplicateNote(id: str) {
    for n in notes {
        if n["id"] == id {
            notes = [n] + notes;
        }
    }
    persist();
}
