"""Cria matriz quadrada identidade"""
def identidade_matriz(N: Any) -> object {
    MI = [];
    for l in range(N) {
        linha = [];
        for c in range(N) {
            if (l == c) {
                valor = 1;
            } else {
                valor = 0;
            }
            linha.append(valor);
        }
        MI.append(linha);
    }
    return MI;
}