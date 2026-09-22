"""Count routes through an n x n grid moving only right and down."""
def euler_problem_15(n: int = 20) -> int {
    num_routes = 1.0;
    for k in range(1, n + 1) {
        num_routes *= (n + k) / k;
    }
    return round(num_routes);
}