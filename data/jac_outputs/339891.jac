"""
input: trgtable{hltpath:[l1seed, hltprescale, l1prescale]}, totalrecorded (float)
output:{hltpath, recorded}
"""
def calculateEffective(trgtable: dict[str, list[float]], totalrecorded: float) -> dict[str, float] {
    result = {};
    for (hltpath, data) in trgtable.items() {
        if len(data) == 3 {
            result[hltpath] = totalrecorded / (data[1] * data[2]);
        } else {
            result[hltpath] = 0.0;
        }
    }
    return result;
}