"""Return the tone number for the given note string."""
def note2num(note_str: str) -> int | str {
    note_list = {
        'C': 0,
        'C#': 1,
        'D-': 1,
        'D': 2,
        'D#': 3,
        'E-': 3,
        'E': 4,
        'E#': 5,
        'F-': 4,
        'F': 5,
        'F#': 6,
        'G-': 6,
        'G': 7,
        'G#': 8,
        'A-': 8,
        'A': 9,
        'A#': 10,
        'B-': 10,
        'B': 11,
        'B#': 0,
        'C-': 11
    };
    note_out = note_list.get(note_str, 'None');
    if type(note_out) == type('None') {
        note_out = 'Add ' + note_str + ' to the note list.';
    }
    return note_out;
}