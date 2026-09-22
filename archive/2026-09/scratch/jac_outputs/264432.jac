"""Parse a gate string into gate name and arguments."""
def get_gate_info(gate: str) -> tuple[str, tuple[int, ...]] {
    g = gate.strip().lower();
    i = g.index("(");
    (gate_name, gate_args) = (g[:i], eval(g[i:]));
    try {
        len(gate_args);
    } except TypeError {
        gate_args = (gate_args,);
    }
    if gate_name == "cx" {
        gate_name = "cnot";
    }
    return (gate_name, gate_args);
}