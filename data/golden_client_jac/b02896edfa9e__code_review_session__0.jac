node Item {}

walker Visitor {
    has target: Item | None = None;

    can direct with Item entry {
        if self.target is not None {
            visit self.target;
        }
        visit [-->];
    }
}
