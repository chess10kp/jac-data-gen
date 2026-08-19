"""_truncate_data: returns a typed TruncResult obj instead of a bare tuple."""

obj TruncResult {
    has data: str, truncated: bool;
}

def _truncate_data(data: str, max_bytes: int) -> TruncResult {
    truncated = len(data) > max_bytes;
    if truncated {
        data = data[:max_bytes] + "\n... (truncated)\n";
    }
    data = data.rstrip("\n");
    return TruncResult(data=data, truncated=truncated);
}

with entry {
    cases = [
        ("hello world", 100),
        ("abcdefghij", 4),
        ("trailing\n\n", 100),
        ("exactlyten", 10)
    ];
    for (d, m) in cases {
        res = _truncate_data(d, m);
        print(str(res.truncated) + "|" + repr(res.data));
    }
}
