"""Extract name in <>."""
def extract_name_angle(line: str) -> str {
    idx1 = line.find('<');
    idx2 = line.find('>');
    return line[idx1 + 1:idx2];
}