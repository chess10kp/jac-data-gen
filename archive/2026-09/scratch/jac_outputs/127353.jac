"""
Tries to split data from line in file, if it splits up then it has pKa data if it doesn't then it's not a data line.
This is very specific to the log files as created by this Epik run, not at all a general use option.
"""
def dataline(line: str) -> tuple[bool, str | None, float | None] {
    try {
        data = line.split(' ');
        pKa = float(data[2]);
        return (True, data[1].strip(), pKa);
    } except Exception {
        return (False, None, None);
    }
}