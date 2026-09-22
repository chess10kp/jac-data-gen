""" Returns a dictionary with each unique token in @tokens as keys. The values are lists:
    the index of the position/s in global @TEXT that the token is found. """
def get_map(tokens: Any) -> object {
    token_index = enumerate(tokens);
    token_map = {};
    for (k, v) in token_index {
        if (v in token_map.keys()) {
            token_map[v].append(k);
        } else {
            token_map[v] = [k];
        }
    }
    return token_map;
}