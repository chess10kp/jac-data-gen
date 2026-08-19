obj OrthoBox {
    has l: float;
    has r: float;
    has b: float;
    has t: float;
    has n: float;
    has f: float;

    def matrix -> list {
        return [2.0 / (self.r - self.l), 0.0, 0.0, 0.0,
                0.0, 2.0 / (self.t - self.b), 0.0, 0.0,
                0.0, 0.0, -2.0 / (self.f - self.n), 0.0,
                -(self.r + self.l) / (self.r - self.l),
                -(self.t + self.b) / (self.t - self.b),
                -(self.f + self.n) / (self.f - self.n), 1.0];
    }
}

def ortho_matrix(box: dict) -> list {
    return OrthoBox(l=box["l"], r=box["r"], b=box["b"],
                    t=box["t"], n=box["n"], f=box["f"]).matrix();
}

with entry {
    print(ortho_matrix({'l': 0.0, 'r': 2.0, 'b': 1.0, 't': 3.0, 'n': 1.0, 'f': 3.0}));
}
