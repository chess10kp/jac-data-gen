"""Search for a number in a sorted list of integers. Big-O Complexity: O(log n)."""
def busqueda(lista: list[int], comienzo: int, final: int, objetivo: int) -> bool {
    if comienzo > final {
        return False;
    }
    medio = (comienzo + final) // 2;
    if lista[medio] == objetivo {
        return True;
    } elif lista[medio] < objetivo {
        return busqueda(lista, medio + 1, final, objetivo);
    } else {
        return busqueda(lista, comienzo, medio - 1, objetivo);
    }
}