# ref-l1-kiln-log-annex
Smell: small monolithic module with all method/function bodies inline.
Target: kiln_log.jac declarations only (obj fields + `def m -> T;` decls + function decls), kiln_log.impl.jac holds
`impl Firing.m -> T {}` and `impl f(args) -> T {}` blocks (6 impls).
Idiom targets: >=5 annex impls; 1 module file.
Native module (no root).
Negatives: glaze faults ignored; double abort ok; aborted pooled; worst picks best.
