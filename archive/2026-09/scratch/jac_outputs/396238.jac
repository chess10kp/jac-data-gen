"""
    get_dict
    """
def get_dict(tokens: list[str], ngram: int, gdict: dict[str, int] | None = None) -> dict[str, int] {
    token_dict = {};
    if gdict is not None {
        token_dict = gdict;
    }
    tlen = len(tokens);
    for i in range(0, tlen - ngram + 1) {
        ngram_token = "".join(tokens[i:(i + ngram)]);
        if token_dict.get(ngram_token) is not None {
            token_dict[ngram_token] += 1;
        } else {
            token_dict[ngram_token] = 1;
        }
    }
    return token_dict;
}