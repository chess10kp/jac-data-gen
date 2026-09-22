"""Update the harmony memory if necessary with the given harmony."""
def update_harmony_memory(
    considered_harmony: list[float],
    considered_fitness: float,
    harmony_memory: list[tuple[list[float], float]]
) -> list[tuple[list[float], float]] {
    if (considered_harmony, considered_fitness) not in harmony_memory {
        worst_index: int | None = None;
        worst_fitness: float = float('+inf');
        for (i, (harmony, fitness)) in enumerate(harmony_memory) {
            if fitness < worst_fitness {
                worst_index = i;
                worst_fitness = fitness;
            }
        }
        if considered_fitness > worst_fitness {
            harmony_memory[worst_index] = (considered_harmony, considered_fitness);
        }
    }
    return harmony_memory;
}