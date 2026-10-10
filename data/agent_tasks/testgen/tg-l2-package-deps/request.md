`deps.jac` has a little package graph (`Package` nodes, `DependsOn` edges) and two walkers built on a shared `Collect` base: `TransitiveDeps` (sorted names of everything a package pulls in) and `InstallOrder` (Kahn's algorithm: dependencies first; packages that are ready at the start go alphabetically, then newly-unblocked ones queue up behind them; `"CYCLE"` if there's a cycle).

There are no tests. Please write `deps_tests.jac` — diamonds, deep chains, packages with no deps, cycles, and the exact install order the current implementation produces. Leave `deps.jac` alone.
