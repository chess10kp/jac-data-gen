def tri_dual(Tri: tuple[int, int, int]) -> tuple[int, int, int] {
    (a1, a2, a3) = Tri;
    return (a2 * a3, a1 * a3, a1 * a2);
}