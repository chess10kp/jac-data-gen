"""Format a note for gedcom output"""
def build_note(
    text: str,
    level: int = 1,
    limit: int = 180,
    strip: bool = True,
    keyword: str = "NOTE"
) -> list[str] {
    note: list[str] = [];
    key = int(level);
    tag = keyword;
    data = text;
    if strip {
        data = data.strip();
    }
    while data != "" {
        index = limit;
        if len(data) < limit {
            index = len(data);
        } else {
            while data[index - 1] == " " and index > 0 {
                index = index - 1;
            }
        }
        chunk = data[:index];
        data = data[index:];
        `entry = "{0} {1} {2}".format(key, tag, chunk);
        note.append(`entry);
        tag = "CONC";
        key = int(level) + 1;
    }
    return note;
}