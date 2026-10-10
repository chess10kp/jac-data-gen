`family.jac` holds a family tree: `Person` nodes connected by `ParentOf` edges (parent → child). People can have one or two recorded parents, and some people's parents simply aren't recorded.

Could you add a `Cousins` walker? Spawned on a person — `w = alice spawn Cousins();` — it should report, once, the sorted list of names of that person's **first cousins**, defined as:

- anyone who shares at least one **grandparent** with the person,
- but who shares **no parent** with them (so siblings and half-siblings are not cousins),
- and is not the person themself.

Each cousin appears once even if they're related through both sides of the family. Someone with no recorded grandparents has no cousins (empty list).

The walker shouldn't modify the tree. Keep `Person`, `ParentOf` and `child_of` as they are.
