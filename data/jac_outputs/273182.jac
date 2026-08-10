"""Given a dataset, break it up into a training and dev set."""
def split_dataset(
    dataset: list[list[tuple[str, str]]],
    word_mapping: dict[str, int],
    label_mapping: dict[str, int],
    percent_testing: float = 0.2,
    shuffle: bool = False
) -> tuple[list[int] | None, list[int] | None, list[int] | None, list[int] | None] {
    return (None, None, None, None);
}