obj Lcg {
    has seed: int;

    def next01() -> float {
        self.seed = (self.seed * 1103515245 + 12345) % 2147483648;
        return float(self.seed) / 2147483648.0;
    }
}

def lcg_stream(spec: dict) -> list {
    gen = Lcg(seed=spec["seed"]);
    return [gen.next01() for i in range(spec["n"])];
}

with entry {
    print(lcg_stream({'seed': 987654321, 'n': 2}));
}
