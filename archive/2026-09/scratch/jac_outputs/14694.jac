"""Read SequenceIDs.txt lines into OrthoFinder ID to name mapping."""
def __read_sequence_ids(data: list[str]) -> dict[str, str] {
    output = {};
    for line in data {
        if line.strip() != '' {
            (k, v) = line.split(': ');
            output[k] = v;
        }
    }
    return output;
}