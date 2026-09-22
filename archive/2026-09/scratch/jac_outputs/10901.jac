"""
	Add linebreaks on whitespace such that no line is longer than `max_len`, unless it contains a single word that's longer.

	There are probably way faster methods, but this is simple and works.
	"""
def add_linebreaks(text: str, max_len: int = 80) -> str {
    br_text = '';
    len_cnt = 0;
    for word in text.split(' ') {
        len_cnt += len(word) + 1;
        if len_cnt > max_len {
            len_cnt = len(word);
            br_text += '\n' + word;
        } else {
            br_text += ' ' + word;
        }
    }
    return br_text[1:];
}