walker SignatureCounter {
    has total: int = 0;

    can start with Hub entry {
        visit [-->[?:Day]];
    }

    can tally with Day entry {
        self.total += len([here-->[?:Visitor]]);
    }
}

with entry {
    # ... build graph ...
    print((root spawn SignatureCounter()).total);
}
