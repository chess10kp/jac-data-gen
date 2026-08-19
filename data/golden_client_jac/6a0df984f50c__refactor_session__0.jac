obj BankAccount {
    has balance: float = 0.0;
    def deposit(amount: float);
    def withdraw(amount: float);
}

impl BankAccount.deposit(amount: float) {
    self.balance += amount;
    print(f"Deposited ${amount}. New balance: ${self.balance}");
}

with entry {
    account = BankAccount();
    account.deposit(100.0);
    account.withdraw(30.0);
    account.withdraw(80.0);
}
