"""
Finds the automatic weighting used between classes of test, e.g., a
"top level" Bonferroni correction, or no correction, etc.
"""
def compute_auto_betweenclass_weighting(
    tests: list[str],
    betweenclass_weighting: bool = True
) -> dict[str, float | int] {
    if betweenclass_weighting {
        return {`test: 1 / len(tests) for `test in tests};
    }
    return {`test: 1 for `test in tests};
}