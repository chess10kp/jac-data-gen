"""Returns zipped handles and labels for which labels contains key."""
def get_lgnd_labels(handles: list[int], labels: list[str], key: str) -> list[tuple[int, str]] {
    return [
        pair
        for pair in zip(handles, labels)
        if key in pair[1]
    ];
}