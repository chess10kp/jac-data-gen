"""Handle if it is pci line"""
def handle_pci_dev(line: str) -> bool {
    if "Region" in line and "Memory at" in line {
        return True;
    }
    if line != '\n' {
        parts = line.split();
        if parts[0][2:3] == ':' and parts[0][5:6] == '.' {
            return True;
        }
    }
    return False;
}