obj NodeRef {
    has value: int = 0;

    def set_value(v: int) -> Self {
        self.value = v;
        return self;
    }

    # New chainable method that also returns Self
    def add(delta: int) -> Self {
        self.value += delta;
        return self;
    }
}

with entry {
    n = NodeRef();
    n.set_value(10).add(5).add(2);
    print(n.value);
}
