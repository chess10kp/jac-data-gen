node Rung { has amt: int; }

walker SpanScan {
    has vals: list = [];
    has spread: int = 0;
    can collect with Rung entry {
        self.vals.append(here.amt);
        visit [-->];
    }
    can settle with exit {
        self.vals.sort();
        self.spread = self.vals[-1] - self.vals[0];
    }
}

def chain_value_range(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    rungs: list = [Rung(amt=int(v)) for v in nums];
    for (a, b) in zip(rungs, rungs[1:]) { a ++> b; }
    return (rungs[0] spawn SpanScan()).spread;
}

with entry {
    print(chain_value_range({'nums': [4, 9, 2, 7]}));
}
