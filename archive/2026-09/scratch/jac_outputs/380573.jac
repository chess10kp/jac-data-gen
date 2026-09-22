"""Get the average score of a set of subscores for a student."""
def getAverageScore(
    result: dict[str, dict[str, dict[str, dict[str, dict[str, int | str]]]]]
) -> float {
    multiple_results = result["extensions"][
        "http://www.boxinabox.nl/extensions/multiple-results"
    ];
    values = [
        elem["value"]
        for elem in list(multiple_results.values())
        if isinstance(elem["value"], int)
    ];
    if len(values) == 0 {
        return 0;
    }
    return sum(values) / len(values);
}