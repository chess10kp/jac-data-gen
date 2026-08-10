"""find the index in a sequence"""
def find_index_of_sequence(data: str, sequence: list[str], startindex: int = 0) -> int {
    index = startindex;
    for token in sequence {
        index = data.find(token, index);
        if index == -1 {
            return -1;
        }
    }
    return index + len(sequence[-1]);
}