walker AltSum { has balance: int = 0; has flip: int = 1; }

node Beat {
    has amt: int;
    can strike with AltSum entry {
        visitor.balance += visitor.flip * self.amt;
        visitor.flip = -visitor.flip;
        visit [-->];
    }
}

def alternating_chain_sum(spec: dict) -> int {
    beats: list = [Beat(amt=int(v)) for v in spec["nums"]];
    if not beats { return 0; }
    for (x, y) in zip(beats, beats[1:]) { x ++> y; }
    return (beats[0] spawn AltSum()).balance;
}

with entry {
    print(alternating_chain_sum({'nums': [10, 3, 2]}));
}
