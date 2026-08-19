def _output_tail(out: str) -> str {
    return "\n".join(out.strip().splitlines()[-8:]);
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
