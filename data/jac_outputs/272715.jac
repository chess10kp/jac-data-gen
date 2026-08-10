"""
    Combine each two chromosomes in population by using single point crossover.
    """
def single_point_crossover(population: list[str], single_point_info: str) -> list[str] {
    crossover_points = [int(p) for p in single_point_info.split("|") if p != ""];
    new_population = [];
    for i in range(0, len(population) - 1, 2) {
        candidate1 = population[i];
        candidate2 = population[i + 1];
        crossover_point = crossover_points[int(i / 2)];
        offspring1 = candidate2[0:crossover_point] + candidate1[crossover_point:];
        offspring2 = candidate1[0:crossover_point] + candidate2[crossover_point:];
        new_population.append(offspring1);
        new_population.append(offspring2);
    }
    if len(population) % 2 == 1 {
        new_population.append(population[len(population) - 1]);
    }
    return new_population;
}