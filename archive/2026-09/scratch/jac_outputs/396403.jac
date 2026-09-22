"""Returns 1 if the two do not share a language, else 0"""
def sharedLangCost(criterion: dict[str, str], frRow: dict[str, str], exRow: dict[str, str]) -> int {
    fluentQ = criterion['fluentQ'];
    learningQ = criterion['learningQ'];
    frLangs = [set(frRow[fluentQ].split(',')), set(frRow[learningQ].split(','))];
    exLangs = [set(exRow[fluentQ].split(',')), set(exRow[learningQ].split(','))];
    return int(
        len(frLangs[0].union(frLangs[1]).intersection(exLangs[0].union(exLangs[1])))
        == 0
    );
}