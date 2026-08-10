"""Count number of indels at end sequence,
        and return number of bps to trim from end"""
def num_of_indels(locus: list[str]) -> int {
    indels = 0;
    for ind in locus {
        parts = ind.split();
        if parts[1].endswith('-') {
            seq = parts[1][::-1];
            for i in range(len(seq)) {
                if seq[i] == '-' {
                    continue;
                } elif i > indels {
                    indels = i;
                    break;
                } else {
                    break;
                }
            }
        }
    }
    return indels;
}