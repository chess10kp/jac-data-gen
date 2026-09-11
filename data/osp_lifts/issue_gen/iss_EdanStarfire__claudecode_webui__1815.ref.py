"""Reference harness: exercises every public function of iss_EdanStarfire__claudecode_webui__1815."""
import importlib

mod = importlib.import_module("iss_EdanStarfire__claudecode_webui__1815")
holder_chains = mod.holder_chains

# Single chain: fastapi -> starlette.
lock = {"root": ["fastapi"], "fastapi": ["starlette"], "starlette": []}
assert holder_chains(lock, "starlette") == [["fastapi", "starlette"]]

# Diamond: two direct deps each pulling the flagged target.
dia = {"root": ["a", "b"], "a": ["t"], "b": ["t"], "t": []}
assert holder_chains(dia, "t") == [["a", "t"], ["b", "t"]]

# Target that is itself a direct dependency: chain of length 1.
assert holder_chains(dia, "a") == [["a"]]

# Unreachable target: empty.
far = {"root": ["a"], "a": ["t"], "t": [], "z": []}
assert holder_chains(far, "z") == []

# Cycle in the lock: simple-path guard keeps chains finite; target inside
# the cycle is still reached without repeating a package.
cyc = {"root": ["a"], "a": ["b"], "b": ["a"], "t": []}
assert holder_chains(cyc, "b") == [["a", "b"]]
assert holder_chains(cyc, "t") == []

# Nested routes of different lengths: x->m->t, x->t, y->t.
nested = {"root": ["x", "y"], "x": ["m", "t"], "y": ["t"], "m": ["t"], "t": []}
assert holder_chains(nested, "t") == [["x", "m", "t"], ["x", "t"], ["y", "t"]]

# Adversarial root order: shorter route listed first; output must sort by
# chain content, not discovery order (a-chain sorts before b-chain).
adv = {"root": ["b", "a"], "a": ["mid"], "mid": ["t"], "b": ["t"], "t": []}
assert holder_chains(adv, "t") == [["a", "mid", "t"], ["b", "t"]]

# Issue-shaped fixture: cryptography held back via litellm->azure-identity
# and via keyring->secretstorage.
lock2 = {
    "root": ["litellm", "keyring"],
    "litellm": ["azure-identity"],
    "azure-identity": ["cryptography"],
    "keyring": ["secretstorage"],
    "secretstorage": ["cryptography"],
    "cryptography": [],
}
assert holder_chains(lock2, "cryptography") == [
    ["keyring", "secretstorage", "cryptography"],
    ["litellm", "azure-identity", "cryptography"],
]

# Empty root: nothing can hold anything back.
assert holder_chains({"root": [], "t": []}, "t") == []

print("iss_EdanStarfire__claudecode_webui__1815 ref OK")
