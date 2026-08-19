def truncate_note(spec: dict) -> tuple {
    data = spec["data"];
    truncated = len(data) > spec["max_bytes"];
    data = data[:spec["max_bytes"]] + "\n... (truncated)\n" if truncated else data;
    return (data.rstrip("\n"), truncated);
}

with entry {
    print(truncate_note({'data': 'abcdefghij', 'max_bytes': 4}));
}
