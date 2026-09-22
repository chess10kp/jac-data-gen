"""Returns the "average" of the normal distributions from NormalParameters.
NormalParameters: a list of length 2 lists, whose entries are the mean and SD of each normal distribution."""
def NormalsAverage(NormalParameters: list[tuple[float, float]]) -> list[float] {
    return [
        sum([p[0] for p in NormalParameters]) / len(NormalParameters),
        (
            sum([p[1] ** 2 for p in NormalParameters])
            / (len(NormalParameters) ** 2)
        ) ** (1 / 2)
    ];
}