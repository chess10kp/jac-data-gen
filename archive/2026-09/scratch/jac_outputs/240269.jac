"""Cria a matrix user (linha) x itens (coluna)."""
def matrix(user_item: dict[str, list[tuple[str, int]]], item_users: dict[str, int]) -> list[list[int]] {
    matriz_user_item = [];
    index_itens = dict();
    cont = 0;
    for item_user in item_users.keys() {
        index_itens[item_user] = cont;
        cont += 1;
    }
    print(f'Quantidade de usuarios: {len(user_item)}');
    for (user, itens) in user_item.items() {
        line_matrix = [0] * len(item_users);
        for item_nota in itens {
            line_matrix[index_itens[item_nota[0]]] = item_nota[1];
        }
        matriz_user_item.append(line_matrix);
    }
    return matriz_user_item;
}