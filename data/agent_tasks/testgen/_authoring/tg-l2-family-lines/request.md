Can you write tests for `family.jac`? It has a `Person` node, `ParentOf` edges, and three walkers: `Descendants` (sorted by birth year, then name), `Ancestors` (alphabetical) and `FirstCousins` (excluding siblings and half-siblings).

Put them in `family_tests.jac`. Build a small family by hand in the tests (a few generations, at least one person with two parents, a half-sibling, and some shared descendants reachable by two paths). Each walker's results and ordering should be checked, plus that each one reports exactly once. Please don't modify `family.jac`.
