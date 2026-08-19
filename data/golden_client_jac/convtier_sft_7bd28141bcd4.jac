walker Cart { has factor: int; has total: int = 0; }

node Stall {
    has price: int;
    can offer with Cart entry {
        visitor.total += self.price * visitor.factor;
        visit [-->];
    }
}

def scaled_chain_total(spec: dict) -> int {
    stalls: list = [Stall(price=int(v)) for v in spec["nums"]];
    if not stalls { return 0; }
    for (a, b) in zip(stalls, stalls[1:]) { a ++> b; }
    return (stalls[0] spawn Cart(factor=int(spec["factor"]))).total;
}

with entry {
    print(scaled_chain_total({'nums': [2, 3, 4], 'factor': 3}));
}
