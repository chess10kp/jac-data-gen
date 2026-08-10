"""fitness_function(solution, answer) Returns a fitness score of a solution compaired to the desired answer. This score is the absolute 'ascii' distance between characters."""
def fitness_function(solution: bytes, answer: bytes) -> int {
    return sum(abs(solution[i] - answer[i]) for i in range(len(answer)));
}