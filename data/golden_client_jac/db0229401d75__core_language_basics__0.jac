obj Account {
    has _balance: float = 0.0,
        balance: float {
            getter -> float { return self._balance; }
            setter(value: float) {
                if value < 0.0 {
                    raise ValueError("balance cannot be negative");
                }
                self._balance = value;
            }
            deleter { self._balance = 0.0; }
        }
}
