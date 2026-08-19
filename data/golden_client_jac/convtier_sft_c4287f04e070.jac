node Pod { has load: int; }

walker MedianScan {
    has vals: list = [];
    has med: float = 0.0;
    can gather with Pod entry {
        self.vals.append(here.load);
        visit [-->];
    }
    can settle with exit {
        self.vals.sort();
        k: int = len(self.vals);
        mid: int = k // 2;
        if k % 2 == 1 { self.med = round(float(self.vals[mid]), 2); }
        else { self.med = round((self.vals[mid - 1] + self.vals[mid]) / 2, 2); }
    }
}

def median_chain_value(spec: dict) -> float {
    nums: list = list(spec["nums"]);
    if not nums { return 0.0; }
    pods: list = [Pod(load=int(v)) for v in nums];
    for (a, b) in zip(pods, pods[1:]) { a ++> b; }
    return (pods[0] spawn MedianScan()).med;
}

with entry {
    print(median_chain_value({'nums': [7, 1, 5]}));
}
