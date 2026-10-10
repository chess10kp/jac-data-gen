# nat-l2-family-cousins
Multi-hop reverse traversal (<-:ParentOf:<- twice), list-anchored hop from grandparents, parent-set exclusion, set dedup.
Alternative: explicit nested loops over helper defs with jid sets.
- includes_self removed: equivalent mutant (self always shares parents with self). Replaced by half_siblings_counted.
