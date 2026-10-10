I'm prototyping a tiny package manager and want the dependency resolution to be graph-native Jac. Please create `deps.jac` with:

* `node Package` — `name: str`, `version: str`
* `edge DependsOn` — from a package to something it depends on

and two walkers that get spawned on a `Package`:

* `TransitiveDeps` — report (once) the sorted list of names of every package this one depends on, directly or indirectly. Not including itself.
* `InstallOrder` — report (once) a list of package names in an order that can actually be installed: every dependency appears before anything that depends on it, each package appears exactly once, and the package the walker was spawned on comes last. If there is a dependency cycle anywhere in what it needs to install, report the string `"CYCLE"` instead of a list.

Shared dependencies (diamonds) are common, so make sure nothing gets listed twice.
