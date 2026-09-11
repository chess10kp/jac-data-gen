"""bsv-blockchain/teranode#1477 — bounded chain-membership OSP lift."""

node Block {
    has block_id: str;
}

edge Parent {}

obj BlockIndex {
    has nodes: dict[str, Block] = {};

    def add_block(block_id: str, parent_id: str | None = None) -> None {
        if block_id in self.nodes {
            raise ValueError(block_id);
        }
        blk = Block(block_id=block_id);
        root ++> blk;
        self.nodes[block_id] = blk;
        if parent_id is not None {
            par = self.nodes.get(parent_id, None);
            if par is None {
                raise KeyError(parent_id);
            }
            blk +>:Parent:+> par;
        }
    }

    def contains(block_id: str) -> bool {
        return block_id in self.nodes;
    }

    def ancestor_chain_naive(tip_id: str) -> list[str] {
        if tip_id not in self.nodes {
            raise KeyError(tip_id);
        }
        w = root spawn AncestorChainWalker(tip=tip_id);
        return w.reports[0] if w.reports else [];
    }

    def is_ancestor(block_id: str, tip_id: str) -> bool {
        if block_id not in self.nodes or tip_id not in self.nodes {
            return False;
        }
        if block_id == tip_id {
            return True;
        }
        chain = self.ancestor_chain_naive(tip_id);
        for bid in chain {
            if bid == block_id {
                return True;
            }
        }
        return False;
    }

    def reject_tx_block_ref(block_ref: str, tip_id: str, max_steps: int) -> str {
        if block_ref not in self.nodes or tip_id not in self.nodes {
            return "reject_unknown";
        }
        if block_ref == tip_id {
            return "accept";
        }
        w = root spawn RejectTxWalker(
            block_ref=block_ref,
            tip=tip_id,
            max_steps=max_steps,
        );
        return w.reports[0] if w.reports else "reject_stale";
    }
}

walker AncestorChainWalker {
    has tip: str;
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};
    has reports: list[list[str]] = [];

    can begin with Root entry {
        for b in [root -->][?:Block] {
            if b.block_id == self.tip {
                visit [b];
            }
        }
    }

    can step with Block entry {
        if here.block_id in self.claimed {
            skip;
        }
        self.claimed[here.block_id] = True;
        self.chain.append(here.block_id);
        visit [here ->:Parent:->][?:Block] else {
            disengage;
        };
    }

    can finish with Root exit {
        report self.chain;
    }
}

walker RejectTxWalker {
    has block_ref: str;
    has tip: str;
    has max_steps: int;
    has steps: int = 0;
    has status: str = "reject_stale";
    has reports: list[str] = [];

    can begin with Root entry {
        for b in [root -->][?:Block] {
            if b.block_id == self.tip {
                visit [b];
            }
        }
    }

    can walk with Block entry {
        if here.block_id == self.block_ref {
            self.status = "accept";
            disengage;
        }
        if self.steps >= self.max_steps {
            self.status = "reject_depth";
            disengage;
        }
        parents = [here ->:Parent:->][?:Block];
        if not parents {
            self.status = "reject_stale";
            disengage;
        }
        par = parents[0];
        self.steps += 1;
        if par.block_id == self.block_ref {
            self.status = "accept";
            disengage;
        }
        visit [par];
    }

    can finish with Root exit {
        report self.status;
    }
}

test "main chain accept within depth" {
    idx = BlockIndex();
    idx.add_block("g");
    idx.add_block("b1", "g");
    idx.add_block("b2", "b1");
    idx.add_block("tip", "b2");
    assert idx.reject_tx_block_ref("b1", "tip", 10) == "accept";
    assert idx.is_ancestor("b1", "tip") is True;
    assert idx.ancestor_chain_naive("tip") == ["tip", "b2", "b1", "g"];
}

test "stale off-chain fork rejects without full naive walk" {
    idx = BlockIndex();
    idx.add_block("g");
    idx.add_block("b1", "g");
    idx.add_block("b2", "b1");
    idx.add_block("tip", "b2");
    idx.add_block("stale", "g");
    assert idx.is_ancestor("stale", "tip") is False;
    assert idx.reject_tx_block_ref("stale", "tip", 100) == "reject_stale";
}

test "depth cap returns reject_depth not accept" {
    idx = BlockIndex();
    idx.add_block("g");
    idx.add_block("b1", "g");
    idx.add_block("b2", "b1");
    idx.add_block("tip", "b2");
    assert idx.reject_tx_block_ref("b1", "tip", 1) == "reject_depth";
}

test "unknown block short-circuits" {
    idx = BlockIndex();
    idx.add_block("g");
    idx.add_block("tip", "g");
    assert idx.reject_tx_block_ref("missing", "tip", 50) == "reject_unknown";
}

test "parent cycle terminates ancestor walk" {
    idx = BlockIndex();
    idx.add_block("a");
    idx.add_block("b", "a");
    idx.add_block("c", "b");
    # simulate corrupt back-edge a -> c without add_block API
    cnode = idx.nodes["c"];
    anode = idx.nodes["a"];
    cnode +>:Parent:+> anode;
    got = idx.ancestor_chain_naive("c");
    assert got == ["c", "b", "a"];
}
