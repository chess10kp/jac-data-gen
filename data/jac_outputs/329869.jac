"""Print lines from standard in."""
def main(stdin: list[str]) {
    for line in stdin {
        line = line.rstrip();
        if line != '' {
            print("{line}\t{num}".format(line=line, num=1));
        }
    }
    return None;
}