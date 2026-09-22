"""Approximate solution of f(x)=0 on interval [a,b] by the secant method."""
def secant(f: Callable[[float], float], a: float, b: float, n: int) -> float | None {
    if f(a) * f(b) >= 0 {
        print("Secant method fails.");
        return None;
    }
    a_n = a;
    b_n = b;
    for _ in range(1, n + 1) {
        m_n = a_n - (f(a_n) * (b_n - a_n)) / (f(b_n) - f(a_n));
        f_m_n = f(m_n);
        if f(a_n) * f_m_n < 0 {
            b_n = m_n;
        } elif f(b_n) * f_m_n < 0 {
            a_n = m_n;
        } elif f_m_n == 0 {
            return m_n;
        } else {
            return None;
        }
    }
    return a_n - (f(a_n) * (b_n - a_n)) / (f(b_n) - f(a_n));
}