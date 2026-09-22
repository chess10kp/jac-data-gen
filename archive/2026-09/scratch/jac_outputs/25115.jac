"""takes a list of keywords and computes all possible ngrams e.g.
		in> ['nice', 'red', 'wine']
		out> [
			('nice',),
			('red',),
			('wine',),
			('nice', 'red'),
			('red', 'wine'),
			('nice', 'red', 'wine')
			]
	"""
def create_ngrams(kw_iterable: list[str], max_n: int | bool = False) -> list[tuple[str, ...]] {
    kw_count = len(kw_iterable);
    output: list[tuple[str, ...]] = [];
    for n in reversed(range(kw_count + 1)[1:]) {
        if n <= max_n {
            for token_index in range(kw_count - n + 1) {
                output.append(tuple(kw_iterable[token_index:token_index + n]));
            }
        }
    }
    return output;
}