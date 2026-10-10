Hi — the community library app (`main.jac`) has walkers for adding books, checking out, returning, availability and an overdue report. We've never tested it and volunteers keep asking whether the overdue list is right.

Could you write `library_tests.jac` covering the walkers (not the CLI)? Due dates are 14 days after checkout (check month/year rollover too), a member can't borrow the same book twice, copies run out, returns free a copy, re-adding a book updates it, and the overdue report is strictly-before-today, sorted by due date then member. Please leave `main.jac` untouched.
