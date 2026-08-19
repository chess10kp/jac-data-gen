obj Account {
    has _balance: float = 0.0,
        balance: float {
            getter -> float;
            setter(value: float);
            deleter;
        }
}

impl Account.balance.getter -> float { return self._balance; }
impl Account.balance.setter(value: float) {
    if value < 0.0 {
        raise ValueError(f"balance cannot be negative, got {value}");
    }
    self._balance = value;
}
impl Account.balance.deleter { self._balance = 0.0; }
