"""Converts secondary structure string into a list of indices of where secondary structure changes (plus start and end coordinates of the sequence)."""
def get_ss(ss_string: str) -> list[int] {
    output = [0];
    for i in range(1, len(ss_string)) {
        if ss_string[i] != ss_string[i - 1] {
            output.append(i);
        }
    }
    if output[-1] != len(ss_string) - 1 {
        output.append(len(ss_string) - 1);
    }
    return output;
}