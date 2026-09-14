"""TARPS-group/pyEKI#15 — native OSP Kronecker operators."""

import math;

node Operator {
    has id: str;
    has kind: str;
    has axis: int = -1;
    has values: list[float] = [];
}

edge Child {}

walker Collect {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    has factors: list[Operator] = [];
    has nodes: list[Operator] = [];

    can step with Operator entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        self.ids.append(here.id);
        self.nodes.append(here);
        if here.kind == "factor" { self.factors.append(here); }
        print here.id;
        for kid in [here ->:Child:->][?:Operator] {
            visit :0: [kid];
        }
    }
}

def make_kron(left_values: list[float], right_values: list[float]) -> Operator {
    product = Operator(id="kron", kind="kron");
    left_node = Operator(id="left", kind="factor", axis=0, values=left_values);
    right_node = Operator(id="right", kind="factor", axis=1, values=right_values);
    product +>:Child:+> left_node;
    product +>:Child:+> right_node;
    return product;
}

def factors_of(product: Operator) -> list[Operator] {
    w = product spawn Collect(claimed={});
    return w.factors;
}

def reachable_ids(product: Operator) -> list[str] {
    w = product spawn Collect(claimed={});
    return w.ids;
}

def find_operator(product: Operator, wanted: str) -> Operator | None {
    w = product spawn Collect(claimed={});
    for item in w.nodes {
        if item.id == wanted { return item; }
    }
    return None;
}

def kron_diag(product: Operator) -> list[float] {
    factors = factors_of(product);
    first: Operator | None = None;
    second: Operator | None = None;
    for factor in factors {
        if factor.axis == 0 { first = factor; }
        if factor.axis == 1 { second = factor; }
    }
    if first is None or second is None { return []; }
    result: list[float] = [];
    for left_value in first.values {
        for right_value in second.values {
            result.append(left_value * right_value);
        }
    }
    return result;
}

def kron_matvec(product: Operator, operand: list[float]) -> list[float] {
    diagonal: list[float] = kron_diag(product);
    if len(operand) != len(diagonal) { return []; }
    result: list[float] = [];
    for i in range(len(operand)) {
        result.append(diagonal[i] * operand[i]);
    }
    return result;
}

def kron_solve(product: Operator, rhs: list[float]) -> list[float] {
    diagonal: list[float] = kron_diag(product);
    if len(rhs) != len(diagonal) { return []; }
    result: list[float] = [];
    for i in range(len(rhs)) {
        if diagonal[i] == 0.0 { return []; }
        result.append(rhs[i] / diagonal[i]);
    }
    return result;
}

def kron_factor(product: Operator) -> list[float] {
    diagonal: list[float] = kron_diag(product);
    result: list[float] = [];
    for value in diagonal {
        result.append(math.sqrt(value));
    }
    return result;
}

def kron_whiten(product: Operator, operand: list[float]) -> list[float] {
    factor: list[float] = kron_factor(product);
    if len(operand) != len(factor) { return []; }
    result: list[float] = [];
    for i in range(len(operand)) {
        if factor[i] == 0.0 { return []; }
        result.append(operand[i] / factor[i]);
    }
    return result;
}

def kron_logdet(product: Operator) -> float {
    factors = factors_of(product);
    first: Operator | None = None;
    second: Operator | None = None;
    for factor in factors {
        if factor.axis == 0 { first = factor; }
        if factor.axis == 1 { second = factor; }
    }
    if first is None or second is None { return 0.0; }
    left_sum: float = 0.0;
    right_sum: float = 0.0;
    for value in first.values { left_sum += math.log(value); }
    for value in second.values { right_sum += math.log(value); }
    return len(second.values) * left_sum + len(first.values) * right_sum;
}

test "orientation and rectangular-free diagonal product" {
    product = make_kron([2.0, 3.0], [5.0, 7.0]);
    assert (kron_matvec(product, [1.0, 2.0, 3.0, 4.0]) == [10.0, 28.0, 45.0, 84.0]);
    assert (kron_diag(product) == [10.0, 14.0, 15.0, 21.0]);
}

test "factor solve whiten and logdet" {
    product = make_kron([1.0, 4.0], [1.0, 9.0]);
    assert (kron_factor(product) == [1.0, 3.0, 2.0, 6.0]);
    assert (kron_solve(product, [1.0, 3.0, 2.0, 6.0]) == [1.0, 1.0, 1.0, 1.0]);
    assert (kron_whiten(product, [1.0, 3.0, 2.0, 6.0]) == [1.0, 1.0, 1.0, 1.0]);
    assert (kron_logdet(product) == math.log(1296.0));
}

test "diamond revisit and cycle claim" {
    a = Operator(id="a", kind="group");
    b = Operator(id="b", kind="group");
    c = Operator(id="c", kind="group");
    d = Operator(id="d", kind="group");
    a +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> d;
    c +>:Child:+> d;
    d +>:Child:+> a;
    assert (sorted(reachable_ids(a)) == ["a", "b", "c", "d"]);
}

test "unknown identifiers and invalid shapes" {
    product = make_kron([], [2.0]);
    assert (find_operator(product, "missing") == None);
    assert (kron_diag(product) == []);
    assert (kron_matvec(product, [1.0]) == []);
    product = make_kron([2.0], [3.0]);
    assert (kron_matvec(product, []) == []);
}
