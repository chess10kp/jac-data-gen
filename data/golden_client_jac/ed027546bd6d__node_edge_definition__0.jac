node Counter {
    has count: int = 0;
}

walker Incrementer {
    has amount: int = 1;

    can start with Root entry {
        visit [-->];
    }

    can increment with Counter entry {
        here.count += self.amount;
    }
}

test "walker increments" {
    counter = root ++> Counter();
    root spawn Incrementer();
    assert counter[0].count == 1;
}

test "walker custom amount" {
    counter = root ++> Counter();
    root spawn Incrementer(amount=5);
    assert counter[0].count == 5;
}
