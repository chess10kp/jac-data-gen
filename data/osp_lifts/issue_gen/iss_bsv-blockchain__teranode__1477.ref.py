#!/usr/bin/env python3
"""Reference harness for bsv-blockchain/teranode#1477."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_bsv-blockchain__teranode__1477.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
assert spec.loader is not None
spec.loader.exec_module(mod)


def _main_chain() -> mod.BlockIndex:
    idx = mod.BlockIndex()
    idx.add_block("g")
    idx.add_block("b1", "g")
    idx.add_block("b2", "b1")
    idx.add_block("tip", "b2")
    return idx


def main() -> None:
    idx = _main_chain()
    assert idx.contains("tip") is True
    assert idx.contains("missing") is False
    assert idx.ancestor_chain_naive("tip") == ["tip", "b2", "b1", "g"]
    assert idx.is_ancestor("b1", "tip") is True
    assert idx.is_ancestor("g", "tip") is True
    assert idx.is_ancestor("tip", "tip") is True
    assert idx.is_ancestor("missing", "tip") is False
    assert idx.reject_tx_block_ref("b1", "tip", 10) == "accept"
    assert idx.reject_tx_block_ref("tip", "tip", 0) == "accept"
    assert idx.reject_tx_block_ref("b1", "tip", 1) == "reject_depth"
    assert idx.reject_tx_block_ref("missing", "tip", 10) == "reject_unknown"

    # known off-chain fork block: still walks full height naively
    idx.add_block("stale", "g")
    assert idx.is_ancestor("stale", "tip") is False
    assert idx.reject_tx_block_ref("stale", "tip", 100) == "reject_stale"

    # parent cycle must terminate
    fork = mod.BlockIndex()
    fork.add_block("a")
    fork.add_block("b", "a")
    fork.add_block("c", "b")
    fork._parent["a"] = "c"  # a <- b <- c <- a
    assert fork.ancestor_chain_naive("c") == ["c", "b", "a"]

    dup = mod.BlockIndex()
    dup.add_block("x")
    try:
        dup.add_block("x")
        raise AssertionError("expected ValueError")
    except ValueError:
        pass
    try:
        dup.add_block("y", "nope")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    try:
        idx.ancestor_chain_naive("nope")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    print("ok")


if __name__ == "__main__":
    main()
