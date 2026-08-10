"""
    Validacion de las marcas, si el pixel coincide con algun color regresa True
    """
def checkStatus(vL: float, vA: float, vB: float) -> bool {
    40 <= vL <= 80 and 50 <= vA <= 80 and -40 <= vB <= 10
}