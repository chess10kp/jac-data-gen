"""
        sums even-indexes elements and multiply at the last
    """
def checkio(`list: Any) -> object {
    soma = 0;
    if (len(`list) > 0) {
        for (pos, item) in enumerate(`list) {
            if ((pos % 2) == 0) {
                soma = soma + item;
            }
        }
        mult = soma * `list[-1];
        return mult;
    } else {
        return 0;
    }
}