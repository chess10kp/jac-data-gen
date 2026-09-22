"""Parse a learning-rate schedule string like 60000:1e-3,20000:1e-4 into phase pairs."""
def phases_from_str(phases_str: str) -> list[list[int | float]] {
    parts = phases_str.split(',');
    phases = [];
    for phase_str in parts {
        splits = phase_str.split(':');
        (iterations, learning_rate) = (int(splits[0]), float(splits[1]));
        phases.append([iterations, learning_rate]);
    }
    return phases;
}