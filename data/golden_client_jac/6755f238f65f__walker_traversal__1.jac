walker Auditor {
    can check with Account entry {
        if not here.active {
            skip;          # this account isn't ours to process; move on
        }
        report here.balance;
        visit [-->];       # not reached for inactive accounts
    }
}
