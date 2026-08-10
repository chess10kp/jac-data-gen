"""Fitness function that determines on the fly whether to use
    a sampling algorithm or not.
    """
def _FunctionSelector(
    population: list[int],
    N: int,
    samples: float | int,
    stdFunction: callable[..., float],
    sampleFunction: callable[..., float],
    baseParams: tuple[int, ...]
) -> float {
    L = len(population);
    combinations = L ** N;
    if samples < 1.0 {
        samples = int(combinations * samples + 0.5);
    }
    if samples == 0 {
        samples = 1;
    }
    if samples < combinations {
        return sampleFunction(population, *(baseParams + (samples, ))) as float;
    }
    return stdFunction(population, *baseParams) as float;
}