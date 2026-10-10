We track our partner museums' collections in `collection.jac`: a `Museum` `Owns` its `Artwork`s, and when a work travels, the artwork gets a `LoanedTo` edge pointing at the borrowing museum with the loan's `start_year` and `end_year` (inclusive). A loan is *active* in a year `y` when `start_year <= y <= end_year`.

I need a walker `OnDisplay` to answer "what can visitors see at this museum in year Y?":

```
w = louvre_ish spawn OnDisplay(year=2027);
```

A work is on display at the museum in that year if it is not `in_conservation`, and either:
- the museum **owns** it and it is **not** on an active loan to some other museum that year, or
- it is **borrowed**: it has an active `LoanedTo` edge pointing at this museum that year.

Report once a list of titles, sorted alphabetically, with no duplicates. Store the count in a `shown: int` field too.

Loans that have ended or not yet started don't affect anything. Please keep the existing declarations and helpers (`acquire`, `lend`) untouched.
