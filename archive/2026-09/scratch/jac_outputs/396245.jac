"""Input: a dictionary of string tuples to values.

    Val: a dictionary of strings to values, where tuples have been separated by spaces"""
def jsonize_phrase_dict(
    phrase_dict: Any,
    val_string: Any = 'frequency',
    term_to_str_fn: Any = lambda (tpl: Any) { ' '.join(tpl); }
) -> object {
    return [
        {'term': term_to_str_fn(term), val_string: val}
        for (term, val) in phrase_dict.items()
    ];
}