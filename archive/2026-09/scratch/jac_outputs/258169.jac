"""Totaliza a quantidade de valores diferentes e totaliza a quantidade de ocorrencias de todos eles.
    INPUT:
    data: dicionario da coluna
    ex:  {'foo11' : 1, 'foo22' : 2}
    OUTPUT:
    answer: tolizador dos valores e ocorrencias.
    ex: 3, 10000
    """
def count_items(dicionario: dict[str, int]) -> tuple[list[str], list[int]] {
    item_types = [];
    count_items = [];
    for chave in dicionario {
        valor = dicionario[chave];
        item_types.append(chave);
        count_items.append(valor);
    }
    print(sum(count_items));
    return (item_types, count_items);
}