def _truncate_data(data: str, max_bytes: int) -> tuple {
    truncated = len(data) > max_bytes;
    if truncated {
        data = data[:max_bytes] + "\n... (truncated)\n";
    }
    data = data.rstrip("\n");
    return (data, truncated);
}

with entry {
    cases = [
        ("hello world", 100),
        ("abcdefghij", 4),
        ("trailing\n\n", 100),
        ("exactlyten", 10)
    ];
    for (d, m) in cases {
        (out, tr) = _truncate_data(d, m);
        print(str(tr) + "|" + repr(out));
    }
}
