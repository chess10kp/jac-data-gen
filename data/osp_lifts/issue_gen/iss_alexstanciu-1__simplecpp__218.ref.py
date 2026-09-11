"""Reference harness: exercises every public function of iss_alexstanciu-1__simplecpp__218."""
import importlib

mod = importlib.import_module("iss_alexstanciu-1__simplecpp__218")
affected = mod.affected
fanout = mod.fanout

# Linear include chain: editing util.hpp rebuilds a.hpp, main.o and util.hpp itself.
units = {"main.o": ["a.hpp"], "a.hpp": ["util.hpp"], "util.hpp": []}
assert affected(units, ["util.hpp"]) == ["a.hpp", "main.o", "util.hpp"]
assert fanout(units, ["util.hpp"]) == 3
# Narrow edit: only the edited source rebuilds (nothing imports it).
assert affected(units, ["main.o"]) == ["main.o"]
assert fanout(units, ["main.o"]) == 1

# Adversarial-order diamond: main's import of util is declared before lib, so
# main is reached via util BEFORE the deeper core first-visit through lib --
# each unit still lands exactly once.
dia = {"main": ["util", "lib"], "lib": ["core"], "util": ["core"], "core": []}
assert affected(dia, ["core"]) == ["core", "lib", "main", "util"]
assert fanout(dia, ["core"]) == 4

# Shared leaf reached from two edited sources at once: union, no duplicates.
assert affected(dia, ["core", "lib"]) == ["core", "lib", "main", "util"]

# Unknown changed id: nothing to rebuild.
assert affected(dia, ["ghost"]) == []
assert fanout(dia, ["ghost"]) == 0

# Import-only name as changed source: propagates but is not itself a unit.
gen = {"main": ["gen.hpp"]}
assert affected(gen, ["gen.hpp"]) == ["main"]
assert fanout(gen, ["gen.hpp"]) == 1

# Import cycle terminates; every member of the cycle rebuilds.
cyc = {"a": ["b"], "b": ["a"], "c": ["a"]}
assert affected(cyc, ["a"]) == ["a", "b", "c"]
assert fanout(cyc, ["a"]) == 3

# No changes: no rebuild.
assert affected(dia, []) == []
assert fanout(dia, []) == 0

# Issue-shaped: body-only edit in one unit rebuilds its object plus the link.
proj = {"link": ["app.o"], "app.o": ["body.phs"], "body.phs": [], "other.o": ["other.phs"], "other.phs": []}
assert affected(proj, ["body.phs"]) == ["app.o", "body.phs", "link"]
assert fanout(proj, ["body.phs"]) == 3

print("iss_alexstanciu-1__simplecpp__218 ref OK")
