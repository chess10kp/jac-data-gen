"""Reference harness: exercises every public function of iss_decalage2__olefile__179."""
from iss_decalage2__olefile__179 import (
    ChainCycleError,
    chain_length,
    is_well_formed,
    load_fat,
    sect_chain,
)

fat = load_fat({0: 3, 3: 7, 7: -2})
assert sect_chain(fat, 0) == [0, 3, 7]
assert chain_length(fat, 0) == 3
assert is_well_formed(fat, 0)

# Self-looping MiniFAT entry: the crafted-file hang must now raise.
bad = load_fat({5: 5})
try:
    sect_chain(bad, 5)
    raise AssertionError("expected ChainCycleError")
except ChainCycleError as e:
    assert str(e) == "cyclic sector chain"
assert chain_length(bad, 5) == -1
assert not is_well_formed(bad, 5)

# Longer loop 8 -> 9 -> 8 detected before any unbounded spin.
loop = load_fat({8: 9, 9: 8})
assert not is_well_formed(loop, 8)

# Free-sector tail tolerated as end of chain.
tail = load_fat({2: -1})
assert sect_chain(tail, 2) == [2]

# Unknown start sector: the walk yields the lone dangling sector.
assert sect_chain(fat, 42) == [42]

print("iss_decalage2__olefile__179 ref OK")
