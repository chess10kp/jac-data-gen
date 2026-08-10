"""Given an output, checks if the modem is in the correct mode"""
def check_if_modem_enabled(out: list[str]) -> int {
    for line in out {
        if '12d1:1446' in line {
            return 0;
        }
        if '12d1:1001' in line {
            return 1;
        }
    }
    return -1;
}