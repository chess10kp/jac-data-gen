"""RL driver (pure-lib): source_index.get_file (truncation step).

Origin: this_is_jac/source_index.jac (the size-cap + trailing-newline trim from
`get_file`, with the byte cap parameterized). Deterministic: if the data is
longer than the cap, truncate to the cap and append a fixed truncation notice,
then strip trailing newlines, returning the data and whether it was truncated.
The marked body is the unit the policy must regenerate; the `with entry` block
exercises it on fixed inputs and prints a deterministic projection.
"""

def _truncate_data(data: str, max_bytes: int) -> tuple {
    # >>>HOLE id="lib_get_file_truncate" instruction="Implement _truncate_data(data, max_bytes): set truncated to True when len(data) is greater than max_bytes; if truncated, replace data with its first max_bytes characters followed by the literal notice newline three-dots space (truncated) newline; then strip trailing newline characters from data; return a tuple of (data, truncated)."
    truncated = len(data) > max_bytes;
    if truncated {
        data = data[:max_bytes] + "\n... (truncated)\n";
    }
    data = data.rstrip("\n");
    return (data, truncated);
    # <<<HOLE
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
