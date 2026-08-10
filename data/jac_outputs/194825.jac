""" Addiert die beiden Matrizen a, b komponentenweise.
    Gibt das Resultat der Addition als neue Matrix c aus. """
def add(a: Any, b: Any) -> object {
    n = len(a);
    c = [[0 for j in range(n)] for i in range(n)];
    for i in range(n) {
        for j in range(n) {
            c[i][j] = a[i][j] + b[i][j];
        }
    }
    return c;
}