glob SPECIAL_LABELS = ('O', '<pad>', '<unk>', '<s>', '</s>', '<STOP>', '<START>');
glob CHUNK_START_TRANSITIONS = {
    ('O', 'I'),
    ('O', 'E'),
    ('E', 'I'),
    ('E', 'E'),
    ('S', 'I'),
    ('S', 'E')
};
glob CHUNK_END_TRANSITIONS = {
    ('B', 'B'),
    ('B', 'O'),
    ('B', 'S'),
    ('I', 'B'),
    ('I', 'O'),
    ('I', 'S')
};

"""
It supports IOB2 or IOBES tagging scheme.
You may also want to try https://github.com/sighsmile/conlleval.
"""
def get_chunks(labels: list[str]) -> list[tuple[int, int, str]] {
    chunks = [];
    (start_idx, end_idx) = (0, 0);
    for idx in range(1, len(labels) - 1) {
        (chunk_start, chunk_end) = (False, False);
        if labels[idx - 1] not in SPECIAL_LABELS {
            (prev_tag, prev_type) = (labels[idx - 1][:1], labels[idx - 1][2:]);
        } else {
            (prev_tag, prev_type) = ('O', 'O');
        }
        if labels[idx] not in SPECIAL_LABELS {
            (tag, chunk_type) = (labels[idx][:1], labels[idx][2:]);
        } else {
            (tag, chunk_type) = ('O', 'O');
        }
        if labels[idx + 1] not in SPECIAL_LABELS {
            (next_tag, next_type) = (labels[idx + 1][:1], labels[idx + 1][2:]);
        } else {
            (next_tag, next_type) = ('O', 'O');
        }
        if tag == 'B' or tag == 'S' or (prev_tag, tag) in CHUNK_START_TRANSITIONS {
            chunk_start = True;
        }
        if tag != 'O' and prev_type != chunk_type {
            chunk_start = True;
        }
        if tag == 'E' or tag == 'S' or (tag, next_tag) in CHUNK_END_TRANSITIONS {
            chunk_end = True;
        }
        if tag != 'O' and chunk_type != next_type {
            chunk_end = True;
        }
        if chunk_start {
            start_idx = idx;
        }
        if chunk_end {
            end_idx = idx;
            chunks.append((start_idx, end_idx, chunk_type));
            (start_idx, end_idx) = (0, 0);
        }
    }
    return chunks;
}