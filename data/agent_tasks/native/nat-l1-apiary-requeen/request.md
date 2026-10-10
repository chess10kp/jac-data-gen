I keep my beehive inspection records in `apiary.jac` — each colony is a `Hive` node hanging off `root`. The `RequeenAudit` walker in there is still an empty shell. Can you finish it?

What I want when I do `root spawn RequeenAudit()`:

- It should go through every `Hive` that is connected directly to `root` (nucleus colonies I hang off another hive are tracked separately — leave those out).
- A hive needs requeening if **either**
  - no queen was seen at the last inspection **and** it has fewer than 3 brood frames, **or**
  - its temper score is 4 or higher (aggressive colonies get requeened whether or not a queen was seen).
- Keep a count of how many hives it looked at in a `checked: int` field on the walker, and collect the flagged tags in a `flagged: list[str]` field.
- When it's done, it should `report` the flagged tags once, as a single list sorted alphabetically (an empty list if nothing needs work).

Please don't change the `Hive` fields or `add_hive` — other scripts use them — and the audit shouldn't modify any hive.
