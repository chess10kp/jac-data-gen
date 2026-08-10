"""Computes the average of positive values in the list."""
def average_above_zero(tab: list[int | float]) -> float {
    if not isinstance(tab, list) {
        raise ValueError('Expected a list as input');
    }
    val_sum = 0.0;
    n_positive_values = 0;
    for value in tab {
        if value > 0 {
            val_sum += float(value);
            n_positive_values += 1;
        }
    }
    if n_positive_values <= 0 {
        raise ValueError('No positive value found');
    }
    return val_sum / n_positive_values;
}