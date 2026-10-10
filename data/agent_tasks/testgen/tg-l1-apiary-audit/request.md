`apiary.jac` has my hive records and the `RequeenAudit` walker that decides which colonies need a new queen. It works, but there isn't a single test for it and I'm about to start changing the rules.

Can you write a proper test suite in `test_apiary.jac` (a separate module that imports from `apiary`)? I want it to actually pin down the behaviour — the brood-frame cutoff, the temper rule, which hives get visited, what gets reported and the walker's counters — so that if I break something later `jac test test_apiary.jac` goes red. Don't change `apiary.jac` itself.
