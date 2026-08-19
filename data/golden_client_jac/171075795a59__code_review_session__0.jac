def example() {
    condition = True;
    items = [1, 2, 3];
    value = 42;

    assert condition;
    assert len(items) > 0, "Items list cannot be empty";
    assert isinstance(value, int), f"Expected int, got {type(value)}";
}

obj Account {
    has balance: float = 0.0;

    def withdraw(amount: float) {
        if amount <= 0.0 {
            raise ValueError("Withdrawal amount must be positive");
        }
        if amount > self.balance {
            raise ValueError("Insufficient funds");
        }
        self.balance -= amount;
    }
}

with entry {
    a = Account(balance=100.0);
    a.withdraw(30.0);
    print(a.balance);
    example();
}
