"""_output_tail: chained one-liner expanded into named steps."""

def _output_tail(out: str) -> str {
    trimmed = out.strip();
    lines = trimmed.splitlines();
    tail = lines[-8:];
    return "\n".join(tail);
}

with entry {
    many = "\n".join(["line" + str(i) for i in range(12)]);
    cases = [
        "  one\ntwo\nthree  ",
        "single",
        "",
        many
    ];
    for c in cases {
        print("===");
        print(_output_tail(c));
    }
}
