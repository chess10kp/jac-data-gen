"""Evaluate whether a record matches a nested query dictionary."""
def evaluate_query(r: dict[str, object], query: dict[str, object]) -> bool {
    if len(query) > 1 {
        results = [evaluate_query(r, {k: v}) for (k, v) in query.items()];
        return all(results);
    }
    key: str = next(iter(query.keys()));
    value = next(iter(query.values()));
    if '.' in key {
        `root = key.split('.')[0];
        previous = '.'.join(key.split('.')[1:]);
        if (`root not in r) {
            return False;
        }
        return evaluate_query(r[`root] as dict[str, object], {previous: value});
    }
    try {
        return r[key] == value;
    } except KeyError {
        return False;
    }
}