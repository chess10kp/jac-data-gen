"""
    :param long: The DNA sequence to search.
    :param short: DNA sequence that we want to match.
    :return: Sub sequences that has the highest pairing rate.
    """
def `match(long: Any, short: Any) -> object {
    maximum = 0;
    homology = '';
    for i in range(((len(long) - len(short)) + 1)) {
        dna = long[i:(i + len(short))];
        count = 0;
        for j in range(len(short)) {
            if (short[j] == dna[j]) {
                count += 1;
            }
        }
        matched = count / len(short);
        if (matched > maximum) {
            maximum = matched;
            homology = dna;
        }
    }
    return homology;
}