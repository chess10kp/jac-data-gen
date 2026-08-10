"""Assign numeric values to dictionary string values."""
def _assign_numbers(dic: dict[str, str | int | float]) -> dict[str, str | int | float] {
    for (k, v) in dic.items() {
        try {
            if '.' in v {
                dic[k] = float(v);
            } else {
                dic[k] = int(v);
            }
        } except ValueError {
            ;
        }
    }
    return dic;
}