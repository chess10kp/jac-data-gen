# ref-l2-pantry-swaps
Smell: one "bucket" Kitchen node on root (found by isinstance scan) holding dict[str, dict[str, bool]] for recipes (ingredient -> optional) and for swaps (original -> replacements); every query loops over nested dicts.
Target: Recipe and Ingredient nodes on root; typed `Needs` edge (Recipe -> Ingredient) with an `optional` flag; one-way `SwapsTo` edge (Ingredient -> Ingredient); queries via edge filters/predicates (`[r ->:Needs:optional == False:->]`, incoming `[i <-:Needs:<-]`).
Idiom targets: >=2 node types, >=1 edge type, 0 dict-typed fields, 0 isinstance calls, >=3 edge filters, >=2 connects.
Tests avoid listing the same ingredient twice in one recipe (dict dedups, edges would not).
Originally drafted as an obj/node facade without root; before the jac.toml server pin, the anchor-free module compiled native at 0.36.1 and `jac test` segfaulted, so it was made root-backed. starter/ and reference/ carry jac.toml `[build] default_codespace = "server"`.
