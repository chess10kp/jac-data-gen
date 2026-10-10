Our community choir roster lives in `choir.jac`: each singer is a `Singer` node on `root` with a `Part` (soprano/alto/tenor/bass). Before each concert the director wants to know whether the sections are balanced. Please add a `SectionCheck` walker.

`root spawn SectionCheck(minimum=3)` should:

- visit every `Singer` on `root`, counting only singers who are `active` **and** have at least 2 rehearsals attended in the current cycle (`rehearsals >= 2`) — others can't sing the concert;
- `report` exactly once, at the end, a dictionary from part name (`"SOPRANO"`, `"ALTO"`, `"TENOR"`, `"BASS"`) to the number of eligible singers in that part — **all four parts must always be present**, with 0 for an empty section;
- also fill a `short: list[str]` field on the walker with the names of the parts whose count is below `minimum`, listed in the enum's declaration order (soprano, alto, tenor, bass).

Don't modify `Part`, `Singer`, or `enrol`.
