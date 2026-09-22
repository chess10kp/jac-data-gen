"""Go from token-level labels to list of entities (start, end, class)."""
def get_span_labels(sentence_tags: Any, inv_label_mapping: Any = None) -> object {
    if inv_label_mapping {
        sentence_tags = [inv_label_mapping[i] for i in sentence_tags];
    }
    span_labels = [];
    last = 'O';
    start = -1;
    for (i, tag) in enumerate(sentence_tags) {
        (pos, _) = (None, 'O') if (tag == 'O') else tag.split('-');
        if (((pos == 'S') or (pos == 'B') or (tag == 'O')) and (last != 'O')) {
            span_labels.append((start, (i - 1), last.split('-')[-1]));
        }
        if ((pos == 'B') or (pos == 'S') or (last == 'O')) {
            start = i;
        }
        last = tag;
    }
    if (sentence_tags[-1] != 'O') {
        span_labels.append(
            (start, (len(sentence_tags) - 1), sentence_tags[-1].split('-')[-1])
        );
    }
    return span_labels;
}