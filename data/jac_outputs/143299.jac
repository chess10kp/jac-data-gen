"""Computes boundary indices for each of the splits in split_probs."""
def _compute_split_boundaries(split_probs: list[tuple[str, float]], n_items: int) -> list[tuple[str, int, int]] {
    if len(split_probs) > n_items {
        raise ValueError(
            'Not enough items for the splits. There are {splits} '
            'splits while there are only {items} items'.format(
                splits=len(split_probs), items=n_items
            )
        );
    }
    total_probs = sum(p for (_, p) in split_probs);
    if abs(1 - total_probs) > 1e-08 {
        raise ValueError('Probs should sum up to 1. probs={}'.format(split_probs));
    }
    split_boundaries = [];
    sum_p = 0.0;
    for (name, p) in split_probs {
        prev = sum_p;
        sum_p += p;
        split_boundaries.append((name, int(prev * n_items), int(sum_p * n_items)));
    }
    split_boundaries[-1] = (split_boundaries[-1][0], split_boundaries[-1][1], n_items);
    return split_boundaries;
}