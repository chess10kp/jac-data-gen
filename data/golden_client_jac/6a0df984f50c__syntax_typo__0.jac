obj BankAccount {
    has balance: float = 0.0;

    def deposit(amount: float) {
        self.balance += amount;
        print(f"Deposited ${amount}. New balance: ${self.balance}");
    }

    def withdraw(amount: float) {
        if amount <= self.balance {
            self.balance -= amount;
            print(f"Withdrew ${amount}. New balance: ${self.balance}");
        } else {
            print("Insufficient funds!");
        }
    }
}

with entry {
    account = BankAccount();
    account.deposit(100.0);
    account.withdraw(30.0);
    account.withdraw(80.0);  # Insufficient funds!
}
