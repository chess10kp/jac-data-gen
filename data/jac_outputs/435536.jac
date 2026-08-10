"""
    Given a dictionary with value: count pairs, build a list.
    """
def sample_builder[T](samples: dict[T, int]) -> list[T] {
    data = [];
    for key in samples {
        data.extend([key] * samples[key]);
    }
    data.sort();
    return data;
}