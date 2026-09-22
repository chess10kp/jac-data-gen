"""Counts to how many files SSP has already been added to."""
def processedcount(file_list: list[str]) -> int {
    n = 0;
    for item in file_list {
        if item[-7:-4] == 'ssp' {
            n += 1;
        }
    }
    return n;
}