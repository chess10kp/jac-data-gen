walker:priv InnerWalker {
    has result: str = "";

    can work with Root entry {
        self.result = "inner data";
    }
}

walker:priv OuterWalker {
    can work with Root entry {
        inner = InnerWalker();
        root spawn inner;
        report inner.result;
    }
}

with entry {
    result = root spawn OuterWalker();
}
