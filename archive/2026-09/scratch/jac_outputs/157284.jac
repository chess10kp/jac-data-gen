def get_z_2p(x_1: float, x_2: float, s1: float, s2: float, n1: int, n2: int) -> float | None {
    if n1 <= 30 or n2 <= 30 {
        print("The sample sizes must be greater than 30.");
    } else {
        s_error = ((s1 ** 2) / n1 + (s2 ** 2) / n2) ** 0.5;
        z = (x_1 - x_2) / s_error;
        return z;
    }
}