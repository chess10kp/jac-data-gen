obj BankAccount {
    has balance: float = 0.0;

    def deposit(amount: float) -> float {
        self.balance += amount;
        return self.balance;
    }

    def withdraw(amount: float) -> float {
        if amount > self.balance {
            raise ValueError("Insufficient funds");
        }
        self.balance -= amount;
        return self.balance;
    }
}

with entry {
    acct = BankAccount(balance=100.0);
    acct.deposit(50.0);
    print(acct.withdraw(30.0));
}
