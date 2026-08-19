node Account { has active: bool = True; has balance: float = 0.0; }

walker Auditor {
    can check with Account entry {
        if here.active {
            report here.balance;
        }
        visit [-->];
    }
}
