# dbg-l2-museum-last-loan-year  (debug, L2, from native/nat-l2-museum-loans)

## bug0 [inconsistent-filter]: borrower-side loan filter treats end_year as exclusive while the owner side treats it as inclusive
- collection.jac: fix by restoring
```
[here <-:LoanedTo:start_year <= y, end_year >= y:<-]
```
(injected as)
```
[here <-:LoanedTo:start_year <= y, end_year > y:<-]
```

