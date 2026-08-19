"""RL driver (pure-lib): capture.CaptureRunner.run_benchmark (failure tail).

Origin: this_is_jac/capture.jac (the last-output tail built inside
`run_benchmark` when no BENCH_JSON was found, isolated from the subprocess
plumbing). Deterministic: strips surrounding whitespace from the captured
output, splits it into lines, and joins the final eight lines with newlines. The
marked body is the unit the policy must regenerate; the `with entry` block
exercises it on fixed inputs and prints a deterministic projection.
"""

def _output_tail(out: str) -> str {
    # >>>HOLE id="lib_bench_output_tail" instruction="Implement _output_tail(out): strip leading and trailing whitespace from out, split the result into lines, take the last eight of those lines, and join them with newline characters."
    return "\n".join(out.strip().splitlines()[-8:]);
    # <<<HOLE
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
