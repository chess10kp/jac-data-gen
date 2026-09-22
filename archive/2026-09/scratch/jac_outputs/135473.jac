"""Cuenta las combinaciones entre clases calculadas y reales."""
def realizar_conteo(arr: list[tuple[str, str]]) -> dict[str, dict[str, int]] {
    res = {};
    for itm in arr {
        if not itm[0] in res {
            res[itm[0]] = {};
        }
        if not itm[1] in res[itm[0]] {
            res[itm[0]][itm[1]] = 1;
        } else {
            res[itm[0]][itm[1]] += 1;
        }
    }
    return res;
}