obj Poly {
    has coeffs: list = [];

    def value_at(x: int) -> int {
        total = 0;
        p = 1;
        for c in self.coeffs {
            total += c * p;
            p *= x;
        }
        return total;
    }

    def derive -> Poly {
        return Poly(coeffs=[i * self.coeffs[i] for i in range(1, len(self.coeffs))]);
    }
}

def poly_at(spec: dict) -> list {
    p = Poly(coeffs=spec["coeffs"]);
    x = spec["x"];
    return [p.value_at(x), p.derive().value_at(x)];
}

with entry {
    print(poly_at({'coeffs': [1, 0, 2], 'x': 3}));
}
