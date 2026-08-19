import from byllm.lib { Image }

obj MathSolution {
    has problem: str;
    has steps: list[str];
    has answer: str;
}

"""Solve the math problem shown in the image."""
def solve_math(img: Image) -> MathSolution by llm();

def print_solution(solution: MathSolution) -> None {
    print(f"Problem: {solution.problem}");
    print("Solution steps:");
    for (idx, step) in enumerate(solution.steps) {
        print(f"  {idx+1}. {step}");
    }
    print(f"Answer: {solution.answer}");
}
