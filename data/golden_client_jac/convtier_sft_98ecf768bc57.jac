walker Rider { has wallet: int; has passed: int = 0; }

node Gate {
    has fee: int;
    can charge with Rider entry {
        if visitor.wallet >= self.fee {
            visitor.wallet -= self.fee;
            visitor.passed += 1;
            visit [-->];
        }
    }
}

def gates_passed(spec: dict) -> int {
    fees: list = list(spec["fees"]);
    if not fees { return 0; }
    gates: list = [Gate(fee=int(v)) for v in fees];
    for (a, b) in zip(gates, gates[1:]) { a ++> b; }
    return (gates[0] spawn Rider(wallet=int(spec["budget"]))).passed;
}

with entry {
    print(gates_passed({'fees': [3, 4, 5], 'budget': 8}));
}
