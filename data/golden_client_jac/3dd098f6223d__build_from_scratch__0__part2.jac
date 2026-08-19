walker:priv InnerWalker {
    has result: str = "";

    can work with Root entry {
        self.result = "inner data";
    }
}

walker:priv OuterWalker {
    can work with Root entry {
        # Spawn inner walker
        inner = InnerWalker();
        root spawn inner;

        # Access inner walker's data via its attributes
        report {"outer": "data", "inner": inner.result};
    }
}

with entry {
    # Usage
    result = root spawn OuterWalker();
    # result.reports[0] = {"outer": "data", "inner": "inner data"}
}
