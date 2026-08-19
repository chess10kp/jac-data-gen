def _validated(values: list) -> list {
    if len(values) == 0 {
        raise ValueError("no samples");
    }
    for v in values {
        if not isinstance(v, (int, float)) {
            raise ValueError(f"bad sample: {v}");
        }
    }
    return values;
}

def _mean(values: list) -> float {
    return sum(values) / len(values);
}

def mean_report(values: list) -> str {
    try {
        clean = _validated(values);
        return f"mean={_mean(clean):.2f} n={len(clean)}";
    } except ValueError as e {
        return f"rejected: {e}";
    }
}

with entry {
    print(mean_report([4, 8, 6]));
}
