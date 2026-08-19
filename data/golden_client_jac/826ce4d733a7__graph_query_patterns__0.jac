"""RL driver (pure-lib): bench._log (prefix a message with ">> " and print it).

Origin: this_is_jac/raylib_shooter/bench.jac (the _log logic, isolated from any io/time/graph
machinery). Deterministic: the body only concatenates a fixed prefix to its str arg and prints,
referencing no globs, rng, IO, or time. The marked body is the unit the
policy must regenerate; the with entry block exercises it on fixed inputs and prints
a deterministic projection.
"""

def _log(msg: str) -> None {
    # >>>HOLE id="lib_log" instruction="Print the given message string prefixed with the two characters greater-than greater-than and a single space (i.e. a '>> ' prefix) using the built-in print."
    print(">> " + msg);
    # <<<HOLE
}

with entry {
    _log("compiling shooter");
    _log("staged raylib shared library set");
}
