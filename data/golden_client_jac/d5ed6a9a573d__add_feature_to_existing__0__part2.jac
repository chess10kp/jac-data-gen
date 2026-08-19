obj Example {
    has field: int = 0;

    def method() {
        local = 5;
        self.field = local;
    }

    def double_field() -> int {
        return self.field * 2;
    }
}

with entry {
    e = Example();
    e.method();
    print(e.double_field());
}
