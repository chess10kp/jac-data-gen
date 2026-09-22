"""
The function newton has several parameters all of them has been talked about a bit below:
                1. f: It is the function/equation to be solevd, the user of the package must define this
                function before calling the solver package "newton".
                2. seed: It is the initial estimation of the value of root for the equation. It can be set at any
                value, but user should be aware of the complexities that can arise because of the
                problems of discontinuous nature of function. Hence, this value should be set with an intelligent
                guess or some amount of ground work
                3. itern: Sets the number of iteration the loop in the function newton should run if the
                convergence has not been reached upto defined solution tolerance, default value of 1E-10.
                4.rounding: It is the rounding of number of signficant digits the solution and numbers generated
                in function are reduced to for printing, default value is 3 decimal places.
                5. diff_tol: It is the forward difference value used in estimation of derivaive of the function
                in the neighborhood of the seed value, default value is 0.1. It can be easily made smaller to
                achieve convergence quicker.
                6. sol_tol: This parameter checks if the seed value in each iteration is changing more than
                this threshold value or not. If the chnage in seed values is smaller than this value, the loop
                in the package exits and the prompt that convergence has been achieved is printed. Hence,
                changing this values is essential to achieve more precise convergence.

    """
def newton(
    f: Callable[[float], float],
    seed: float,
    itern: int = 10,
    rounding: int = 3,
    diff_tol: float = 0.1,
    sol_tol: float = 1e-10
) -> float {
    soln = [];
    print(30 * "*", "Newton's method convergence visualization", 30 * "*");
    print("f(n)", "n", sep="\t");
    print(20 * "*");
    for i in range(1, itern) {
        seed = seed - (f(seed) * diff_tol) / (f(seed + diff_tol) - f(seed));
        soln.append(seed);
        if len(soln) > 2 and soln[-2] - soln[-1] < sol_tol {
            print(
                "Convergene of solution achieved! after",
                i,
                "iterations! at seed value of:",
                round(seed, rounding)
            );
            break;
        }
        print(round(f(seed), rounding), round(seed, rounding), sep="\t");
    }
    return seed;
}