obj Wallet {
    has balance: int = 0;

    def add(amount: int) -> None { self.balance += amount; }

    def spend(amount: int) -> None { self.balance -= amount; }
}

with entry {
    w = Wallet(balance=100);
    w.spend(30);
    print(w.balance);
}
