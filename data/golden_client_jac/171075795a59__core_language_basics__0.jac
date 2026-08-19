def example() {
    condition = True;
    items = [1, 2, 3];
    value = 42;

    # Basic assertion
    assert condition;

    # Assertion with message
    assert len(items) > 0, "Items list cannot be empty";

    # Type checking
    assert isinstance(value, int), f"Expected int, got {type(value)}";
}

# Invariant checking in class methods
obj Account {
    has balance: float = 0.0;

    def withdraw(amount: float) -> None {
        assert amount > 0, "Withdrawal amount must be positive";
        assert amount <= self.balance, "Insufficient funds";
        self.balance -= amount;
    }
}
