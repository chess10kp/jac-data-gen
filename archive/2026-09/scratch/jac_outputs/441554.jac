"""Find Flash Control Block offset."""
def find_fcb_offset(content: bytes) -> int {
    try {
        index = content.index(b'FCB ');
        if index > 4 {
            return index - 4;
        }
        return -1;
    } except ValueError {
        return -1;
    }
}