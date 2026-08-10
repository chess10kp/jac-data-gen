"""See: https://github.com/facebookresearch/ParlAI/blob/master/parlai/core/dict.py#L31
        token_dict:  {'hello world', 'ol boy'}
        text: ['hello', 'world', 'buddy', 'ol', 'boy']
        n: max n of n-gram
        ret: ['hello world', 'buddy', 'ol boy']
    """
def find_ngrams(token_dict: set[str], text: list[str], n: int) -> list[str] {
    if n <= 1 {
        return text;
    }
    saved_tokens = [];
    search_tokens = text[:];
    next_search = [];
    while len(search_tokens) >= n {
        ngram = ' '.join(search_tokens[:n]);
        if ngram in token_dict {
            sub_n = min(len(next_search), n - 1);
            saved_tokens.extend(find_ngrams(token_dict, next_search, sub_n));
            next_search.clear();
            saved_tokens.append(ngram);
            search_tokens = search_tokens[n:];
        } else {
            next_search.append(search_tokens.pop(0));
        }
    }
    remainder = next_search + search_tokens;
    sub_n = min(len(remainder), n - 1);
    saved_tokens.extend(find_ngrams(token_dict, remainder, sub_n));
    return saved_tokens;
}