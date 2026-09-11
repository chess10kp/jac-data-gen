"""bsv-blockchain/teranode#1477 — Chain-membership check with bounded ancestor walk.

Naive parent-pointer walks from the active tip traverse the full chain height
even when rejecting a transaction that references an old, off-chain block.
The bounded path caps steps and rejects unknown ids without walking to genesis.
"""

from __future__ import annotations


class BlockIndex:
    """Fresh handle per fixture; parent map and visited-set loops live here."""

    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._nodes: set[str] = set()

    def add_block(self, block_id: str, parent_id: str | None = None) -> None:
        if block_id in self._nodes:
            raise ValueError(block_id)
        if parent_id is not None and parent_id not in self._nodes:
            raise KeyError(parent_id)
        self._nodes.add(block_id)
        self._parent[block_id] = parent_id

    def contains(self, block_id: str) -> bool:
        return block_id in self._nodes

    def ancestor_chain_naive(self, tip_id: str) -> list[str]:
        if tip_id not in self._nodes:
            raise KeyError(tip_id)
        chain: list[str] = [tip_id]
        seen: set[str] = {tip_id}
        cur = tip_id
        while self._parent.get(cur) is not None:
            par = self._parent[cur]
            if par in seen:
                break
            seen.add(par)
            chain.append(par)
            cur = par
        return chain

    def is_ancestor(self, block_id: str, tip_id: str) -> bool:
        if block_id not in self._nodes or tip_id not in self._nodes:
            return False
        if block_id == tip_id:
            return True
        return block_id in self.ancestor_chain_naive(tip_id)

    def reject_tx_block_ref(self, block_ref: str, tip_id: str, max_steps: int) -> str:
        if block_ref not in self._nodes or tip_id not in self._nodes:
            return "reject_unknown"
        if block_ref == tip_id:
            return "accept"
        cur = tip_id
        seen: set[str] = {tip_id}
        steps = 0
        while steps < max_steps:
            par = self._parent.get(cur)
            if par is None:
                return "reject_stale"
            if par in seen:
                return "reject_stale"
            steps += 1
            if par == block_ref:
                return "accept"
            seen.add(par)
            cur = par
        return "reject_depth"
