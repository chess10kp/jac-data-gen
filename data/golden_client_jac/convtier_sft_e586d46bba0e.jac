obj Account {
    has balance: int = 0;
    has rejected: int = 0;
    has history: list = [];

    def apply(op: dict) -> None {
        match op["kind"] {
            case "dep":
                self.balance += op["amt"];
                self.history.append(op["amt"]);
            case "wd":
                if op["amt"] > self.balance {
                    self.rejected += 1;
                } else {
                    self.balance -= op["amt"];
                    self.history.append(-op["amt"]);
                }
        }
    }

    def summary -> list {
        return [self.balance, self.rejected, len(self.history)];
    }
}

def process_ledger(ops: list) -> list {
    acct = Account();
    for op in ops {
        acct.apply(op);
    }
    return acct.summary();
}

with entry {
    print(process_ledger([{'kind': 'dep', 'amt': 100}, {'kind': 'wd', 'amt': 30}, {'kind': 'wd', 'amt': 200}]));
}
