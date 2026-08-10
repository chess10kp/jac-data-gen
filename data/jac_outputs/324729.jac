"""
  Remove keys that have either null values, empty strings or empty arrays
  See: https://stackoverflow.com/a/27974027/5472444
  """
def prune_none_and_empty(d: Any) -> object {
    if not isinstance(d, (dict, list)) {
        return d;
    }
    if isinstance(d, list) {
        return [
            v
            for v in [prune_none_and_empty(v) for v in d]
            if v
        ];
    }
    return {
        k: v
        for (k, v) in ((k, prune_none_and_empty(v)) for (k, v) in d.items())
        if v
    };
}