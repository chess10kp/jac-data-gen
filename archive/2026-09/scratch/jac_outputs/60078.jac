"""Returns if the line is a header line used in MACS/MACS2 xls."""
def is_macs_header(line: str) -> bool {
    line = line.strip();
    return line.startswith('#') or line.split('\t')[0] == 'chr';
}