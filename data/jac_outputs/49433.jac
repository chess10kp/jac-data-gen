"""Genera el valor de L del string de color."""
def generarValorB(valor: str) -> float {
    (_, _, b) = valor.split("/");
    return float(b);
}